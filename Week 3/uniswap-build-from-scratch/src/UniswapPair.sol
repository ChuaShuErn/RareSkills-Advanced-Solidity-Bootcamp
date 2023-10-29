// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UniswapRewardToken.sol";
import {console} from "forge-std/console.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {intoUint256} from "@prb/math/ud60x18/Casting.sol";
import {gm} from "@prb/math/ud60x18/Math.sol";

contract UniswapPair is UniswapRewardToken {
    using SafeERC20 for IERC20;
    //First let's handle liquidity

    uint256 private constant MINIMUM_LIQUIDITY = 10_000;

    uint256 private constant INITIAL_SHARES = 100_000;

    //first token
    IERC20 public tokenA;
    //second token
    IERC20 public tokenB;

    //Uniswap does its own accounting for balanceOfTokenA
    uint256 public balanceOfTokenA;
    //Uniswap does its own accounting for balanceOfTokenB
    uint256 public balanceOfTokenB;

    //1. Token Selection
    // Verify that the tokens are valid, legitimate, and have a purpose in the ecosystem
    function initilizeTokens(address _tokenA, address _tokenB) external {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function calculateRatio(
        uint256 tokenAInput,
        uint256 tokenBInput,
        uint256 currentBalanceOfTokenA,
        uint256 currentBalanceOfTokenB,
        UD60x18 slippagePercentage
    ) internal pure returns (uint256 refinedTokenA, uint256 refinedTokenB) {
        //current reserve BalanceOfTokenA and B will not be zero
        //first check token A input
        //convert uint to ud
        UD60x18 UDtokenAInput = ud(tokenAInput);
        UD60x18 UDtokenBInput = ud(tokenBInput);

        //what is the minimumAmountOfTokenA
        UD60x18 minimumAmountOfTokenA = slippagePercentage.mul(UDtokenAInput);
        UD60x18 minimumAmountOfTokenB = slippagePercentage.mul(UDtokenBInput);

        //what is the minimumAmountOfTokenB
        //current Balance is in wei

        UD60x18 optimalAmountOfB = (UDtokenAInput * ud(currentBalanceOfTokenB)) / ud(currentBalanceOfTokenA);

        if (optimalAmountOfB <= UDtokenBInput) {
            //optimal amount of B must be at least equal to slippageAmountOfTokenB
            require(optimalAmountOfB >= minimumAmountOfTokenB, "Insufficient Token B Amount");

            return (tokenAInput, intoUint256(optimalAmountOfB));
        } else {
            UD60x18 optimalAmountofA = (UDtokenBInput * ud(currentBalanceOfTokenA)) / ud(currentBalanceOfTokenB);
            require(optimalAmountofA >= minimumAmountOfTokenA, "Insufficient Token A Amount");
            return (intoUint256(optimalAmountofA), tokenBInput);
        }
    }

    /**
     * @dev
     *    @param liquidityProvider address of liquidity provider, we don't use msg.sender,
     *    if we want to use a router contract
     *    @param tokenAInput, desiredAmount of TokenA by User,
     *    is uint256 because tokens are calculated in wei
     *    @param tokenBInput, desiredAmount of TokenB by User,
     *    is uint256 because tokens are calculated in wei
     *    @param slippagePercentage Acceptable difference of actual price
     *       each token due to volatility
     */
    function addLiquidity(
        address liquidityProvider,
        uint256 tokenAInput,
        uint256 tokenBInput,
        UD60x18 slippagePercentage
    ) external {
        //Here we will prevent any 0 input for each token
        require(tokenAInput > 0, "Invalid Input");
        require(tokenBInput > 0, "Invalid Input");
        require(slippagePercentage.gt(ud(0)), "Invalid Slippage %");
        // user wants to deposit deposit X number of tokenA and Y number of tokenB
        uint256 refinedAmountOfTokenA;
        uint256 refinedAmountOfTokenB;

        //storage pointer of the current reserves
        uint256 _currentBalanceOfA = balanceOfTokenA;
        uint256 _currentBalanceOfB = balanceOfTokenB;

        // how to handle decimal for slippage percentage
        // frontend precalculates it
        // but let's use this oppurtunity to use the math libraries

        //TODO: check if UniswapV2 allows a deposit of only 1 token
        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            //initialDeposit, this is the ratio now
            refinedAmountOfTokenA = tokenAInput;
            refinedAmountOfTokenB = tokenBInput;

            //mint minimum liquidity to the contract
            //mint LPreward to the liquidityProvider
        } else {
            //When there is existing liquidity
            //the LP shares need to be calculated
            //
            (refinedAmountOfTokenA, refinedAmountOfTokenB) =
                calculateRatio(tokenAInput, tokenBInput, _currentBalanceOfA, _currentBalanceOfB, slippagePercentage);
        }

        //then minimum liquidity will occur
        //if it is the initial deposit?

        //do the transfer: UniswapV2 will accept any amount of tokens provider
        //LP Reward will still be calculated by examining the ratio of tokenA and tokenB
        // Uniswap will not "return" any excess tokens
        // Price change will create arbitrage oppurtuninity
        // This is intended/ fine

        SafeERC20.safeTransferFrom(tokenA, liquidityProvider, address(this), refinedAmountOfTokenA);
        SafeERC20.safeTransferFrom(tokenB, liquidityProvider, address(this), refinedAmountOfTokenB);

        uint256 _newBalanceOfA = tokenA.balanceOf(address(this));
        uint256 _newBalanceOfB = tokenB.balanceOf(address(this));

        uint256 actualADeposited = _newBalanceOfA - refinedAmountOfTokenA;
        uint256 actualBDeposited = _newBalanceOfB - refinedAmountOfTokenB;

        uint256 LPReward;
        if (_totalSupply == 0) {
            UD60x18 geometricMean = gm(ud(actualADeposited), ud(actualBDeposited));
            LPReward = geometricMean.unwrap() - MINIMUM_LIQUIDITY;
            // we are going to mint the minimum liquidity
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            //This is where Uniswap punishes naive Liquidity Providers
            // if the ratio is 50:50,
            // and the provider somehow provides as 90:10
            // in the actual Uniswap contract,
            //they can bypass the Uniswap Router
            // the pool will accept all tokens
            // but will take LP reward of the person as if he put in 10:10 (as of the original ratio)
            // so that is why we take the min of tokensAprovided * totalSupply /tokenAReserve, tokensBprovided * totalSupply/tokenBReserve
            UD60x18 rewardForTokenA = ud(actualADeposited).mul(ud(_totalSupply)).div(ud(_currentBalanceOfA));
            UD60x18 rewardForTokenB = ud(actualBDeposited).mul(ud(_totalSupply)).div(ud(_currentBalanceOfB));
            //PRb has no min math...?
            if (rewardForTokenA > rewardForTokenB) {
                LPReward = rewardForTokenB.unwrap();
            } else {
                LPReward = rewardForTokenA.unwrap();
            }
        }
        //check that LPReward is not 0
        //TODO: explain why
        require(LPReward > 0, "LPReward cannot be zero");
        _mint(liquidityProvider, LPReward);
        //internal accounting
        internalAccounting();

        // check the balances now
    }

    function internalAccounting() private {}
}
