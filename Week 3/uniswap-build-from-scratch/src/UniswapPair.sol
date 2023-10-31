// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./UniswapRewardToken.sol";
import {console} from "forge-std/console.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {intoUint256} from "@prb/math/ud60x18/Casting.sol";
import {gm,sqrt} from "@prb/math/ud60x18/Math.sol";

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

    //cumulative price
    uint256 public priceOfACumulativeLast;
    uint256 public priceOfBCumulativeLast;

    address public feeBeneficiary;
    
    struct SnapshotStruct{
        uint256 snapshotPriceOfA;
        uint256 snapshotPriceOfB;
    }

    mapping(uint256 snapshotTime => SnapshotStruct) snapshotMap;

    uint256 public blockTimestampLast;

    //kLast, renamed to make things clearer for me
    uint256 public lastSnapshotOfProductOfReserves;

    //TODO: Remove this
    bool public feeOn;

    event PriceSnapshotTaken(uint256 price0CumulativeLast, uint256 price1CumulativeLast, uint256 snapshotTime);
    event AddLiquidity(address liquidityProvider, uint256 amountOfTokenA, uint256 amountOfTokenB);

    constructor(address _tokenA, address _tokenB, address _feeBeneficiary) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        feeBeneficiary = _feeBeneficiary;
    }

    //TODO: Remove this method
    //1. Token Selection
    // Verify that the tokens are valid, legitimate, and have a purpose in the ecosystem
    function initilizeTokens(address _tokenA, address _tokenB) external {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        blockTimestampLast = block.timestamp;
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
     * It will start at the very beginning of the user journey, so it will include 
     * what would normally be in the router
     *
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

        tokenA.safeTransferFrom(liquidityProvider, address(this), refinedAmountOfTokenA);
        tokenB.safeTransferFrom(liquidityProvider, address(this), refinedAmountOfTokenB);

        uint256 _newBalanceOfA = tokenA.balanceOf(address(this));
        uint256 _newBalanceOfB = tokenB.balanceOf(address(this));

        uint256 actualADeposited = _newBalanceOfA - refinedAmountOfTokenA;
        uint256 actualBDeposited = _newBalanceOfB - refinedAmountOfTokenB;

        bool isFeeOn = _mintFee(_newBalanceOfA,_newBalanceOfB, _totalSupply);

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
            // so that is why we take the min of 
            // tokensAprovided * totalSupply /tokenAReserve, tokensBprovided * totalSupply/tokenBReserve
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
        internalAccounting(_newBalanceOfA, _newBalanceOfB);

        // check the balances now
        if(isFeeOn){
            lastSnapshotOfProductOfReserves = balanceOfTokenA * balanceOfTokenB;
        }
        emit AddLiquidity(msg.sender, actualADeposited, actualBDeposited);
        
    }
    
    /**
    * @dev This function is the remove Liquidity function.
    * It will start at the very beginning of the user journey, so it will include 
    * what would normally be in the router
    * @param liquidityRemover, address ,user that wants to withdraw liquidity
    * @param desiredAmountOfLPTokensToBurn uint256, amount of tokens the user needs to burn
    */
    function removeLiquidity(address liquidityRemover,uint256 desiredAmountOfLPTokensToBurn) external{

        //transfer the LP tokens first
        IERC20 LPToken = IERC20(address(this));

        uint256 previousLPTokenBalance = LPToken.balanceOf(address(this));
        LPToken.safeTransferFrom(liquidityRemover, address(this), desiredAmountOfLPTokensToBurn);
        uint256 amountOfLPTokensToBurn = LPToken.balanceOf(address(this)) - previousLPTokenBalance;

        //check slippage


        //require(balanceOf(liquidityRemover)>= amountOfLPTokensToBurn, "Not enough LP tokens");
        //calculate how much liquidity
        uint256 currentBalanceOfA = tokenA.balanceOf(address(this));
        uint256 currentBalanceOfB = tokenB.balanceOf(address(this));
        uint256 _totalSupply = totalSupply();

        UD60x18 amountOfTokenAToBeWithdrawn = ud(currentBalanceOfA * amountOfLPTokensToBurn).div(ud(_totalSupply));
        UD60x18 amountOfTokenBToBeWithdrawn = ud(currentBalanceOfB * amountOfLPTokensToBurn).div(ud(_totalSupply));
    // need to check slippage

        require(amountOfTokenAToBeWithdrawn > ud(0),"Insuffient LP tokens to burn");
        require(amountOfTokenBToBeWithdrawn > ud(0),"Insuffient LP tokens to burn");

       
     


    } 

    /**
     * @dev This function is to do internal accounting of keep tracking reserve0 and reserve1,
     * which is balanceOfTokenA and balanceOfTokenB
     *    @param newBalanceofA uint256, new total amount of Token A in this liquidity pool
     *    @param newBalanceofB uint256, new total amount of Token B in this liquidity pool
     *    is uint256 because tokens are calculated in wei
     */
    function internalAccounting(uint256 newBalanceofA, uint256 newBalanceofB) private {
        //In practice, when you want to calculate a TWAP over an interval,
        // you would need two points in time the beginning and the end of the desired
        // interval

        // In UniswapV2, priceCumulativeLast is always overriden. How can we calculate
        // the TWAP if we only have the latest point in time?
        // We have to store "checkpoints" of price cumulative last somewhere (offchain usually)
        // or emit Events

        //for the sake of learning, let's do both onchain

        //lets do events first
        // we need time checkpoint of price0cumulativeLast, price1cumulativeLast, and timestamp
        // then do query it on chain
        // we need 2 inputs

        //timestamp A and timestamp B
        // we can use a mapping
        // mapping(uint256 timestamp =>Struct(uint256 price0cumulativeLastmuint256 price1cumulativeLast))
        uint256 currentTime = block.timestamp;
        uint256 timePassedSinceLiquidityEvent = currentTime - blockTimestampLast;

        //checking if you are a transaction where timePassed is gt 0
        if (timePassedSinceLiquidityEvent > 0 && balanceOfTokenA > 0 && balanceOfTokenB > 0) {
            
            UD60x18 priceOfACL = ud(balanceOfTokenA)/ud(balanceOfTokenB) * ud(timePassedSinceLiquidityEvent);
            UD60x18 priceOfBCL = ud(balanceOfTokenB)/ud(balanceOfTokenA) * ud(timePassedSinceLiquidityEvent);
            priceOfACumulativeLast += priceOfACL.unwrap();
            priceOfBCumulativeLast += priceOfBCL.unwrap();
            //event way
            emit PriceSnapshotTaken(priceOfACumulativeLast, priceOfBCumulativeLast, currentTime);
            //contract variable way
            //but this one is not so good, how to get a good range?
            snapshotMap[currentTime] = SnapshotStruct(balanceOfTokenA,balanceOfTokenB);
        }

        balanceOfTokenA = newBalanceofA;
        balanceOfTokenB = newBalanceofB;
        blockTimestampLast = currentTime;
    }

    /**
     * @dev This function is to 
     * 1) update the kLast snapshot,
     * and 2) to mint a portion of the swap fees
     * to a trusted account
     *
     * This is only done for BIG liquidity events, addLiquidity / removeLiquidity
     * and not for trade for gas savings
     */
    function _mintFee(uint256 _newBalanceOfA,uint256 _newBalanceOfB, uint256 _totalSupply) private returns (bool isFeeOn){

        //TODO: Add factory contract to include treasury address
        address _feeBeneficiary = feeBeneficiary;
        isFeeOn = true;
        //if fee is on
        if(isFeeOn){
            //and that kLast is not zero
            if(lastSnapshotOfProductOfReserves !=0){

                //get the geometric mean of the old pool
               UD60x18 oldPoolGm = sqrt(ud(lastSnapshotOfProductOfReserves));
               //get geometric mean of the new pool
               UD60x18 newPoolGm= gm(ud(_newBalanceOfA), ud(_newBalanceOfB));
               uint256 feesMinted;
               
               //if the pool DID increase
               if(newPoolGm>oldPoolGm){
                //This formula gives you the accumulated fees between
                //t1 and t2 as a percentage of the liquidity in the pool at t2
                //This complicated formula is in Uniswap Whitepaper
                //https://uniswap.org/whitepaper.pdf
                // So numerator and Denomintor is just the code version of the
                // formula in the whitepaper
                // if 1/6 fees, then its (1/(1/6)-1) = 5
                // if its 1/3 fees, then its (1/(1/3)-1) = 2
                    UD60x18 numerator = ud(_totalSupply).mul(newPoolGm - oldPoolGm);
                    UD60x18 denominator = newPoolGm.mul(ud(5)).add(oldPoolGm);
                    feesMinted = (numerator.div(denominator)).unwrap();
                    if(feesMinted>0){
                        _mint(_feeBeneficiary, feesMinted);
                    }
                    
               }
               else if(lastSnapshotOfProductOfReserves != 0) {
                //set state back to zero
                //refund feature ?
                //So this is not really necessary
                 lastSnapshotOfProductOfReserves = 0;
               }

            }
        }
    }
}
