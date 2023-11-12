// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {intoUint256} from "@prb/math/ud60x18/Casting.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";
import {gm, sqrt, ceil, inv} from "@prb/math/ud60x18/Math.sol";
import "./UniswapRewardToken.sol";
import {IUniswapCallee} from "./IUniswapCallee.sol";
//import "prb-math/contracts/PRBMathUD60x18.sol";

contract UniswapPair is UniswapRewardToken {
    //using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    //The difference between "conversion" and "casting" is that
    //conversion functions multiply or divide the inputs,
    //whereas casting functions simply cast them.
    //Anything that is to be converted into UD60x18 is on a 1e18 scale
    uint256 private constant PRB_MATH_SCALE = 1e18;

    uint256 private constant MINIMUM_LIQUIDITY = 1_000;

    /**
     * @dev allows us to change this percentage derived from Uniswap white paper
     * default UniswapV2 denominator is 6, indicating that we will mint 1/6th of the increase
     * to the beneficiary
     */
    uint256 public mintFeePercentageDenominator = 6;

    /**
     * @dev allows us to change the swapFee Percentage from the default 0.3%
     *     this is a uint meant to be divided by a thousand
     *    0.003e18 = 0.3%;
     */
    uint256 public swapFeePercentageVariable = 0.003e18;

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

    //TODO: PlaceHolder remove this later
    address public factory = address(10);

    struct SnapshotStruct {
        uint256 snapshotPriceOfA;
        uint256 snapshotPriceOfB;
    }

    mapping(uint256 snapshotTime => SnapshotStruct) snapshotMap;

    uint256 public blockTimestampLast;

    //kLast, renamed to make things clearer for me
    uint256 public lastSnapshotOfProductOfReserves;

    bool public feeOn;

    event PriceSnapshotTaken(uint256 price0CumulativeLast, uint256 price1CumulativeLast, uint256 snapshotTime);
    event AddLiquidity(address liquidityProvider, uint256 amountOfTokenA, uint256 amountOfTokenB);
    event RemoveLiquidity(address liquidityRemover, uint256 amountOfTokenA, uint256 amountOfTokenB);
    event RegularSwap(
        address swapper, uint256 amountAIn, uint256 amountBIn, uint256 amountAout, uint256 amountBout, address to
    );
    event FlashLoan(address to, uint256 amountAOut, uint256 amountAIn, uint256 amountBOut, uint256 amountBIn);

    constructor(address _tokenA, address _tokenB, address _feeBeneficiary) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        feeBeneficiary = _feeBeneficiary;
        blockTimestampLast = block.timestamp;
    }

    function setMintFeePercentageDenominator(uint256 newMintFeePercentage) external {
        //TODO: only factory can call this
        require(newMintFeePercentage != 0, "Cannot be zero");
        require(msg.sender == factory, "Only Factory may call this");
        mintFeePercentageDenominator = newMintFeePercentage;
    }

    function setFeeOn(bool value) external {
        require(msg.sender == factory, "Only Factory may call this");
        feeOn = value;
    }

    //TODO: Make Internal. We are testing
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
        // console.log("debug1");
        UD60x18 UDtokenAInput = convert(tokenAInput);
        UD60x18 UDtokenBInput = convert(tokenBInput);
        //console.log("UDTokenAInput:", UDtokenAInput.unwrap());

        //what is the minimumAmountOfTokenA

        //console.log("debug2");
        //first we compare tokenB

        UD60x18 minimumAmountOfTokenB = UDtokenBInput - slippagePercentage.mul(UDtokenBInput);
        //console.log("minimumAmountocTokenA:", convert(minimumAmountOfTokenA));
        //console.log("minimumAmountocTokenB:", convert(minimumAmountOfTokenB));
        //what is the minimumAmountOfTokenB
        //current Balance is in wei

        //console.log("debug3");
        UD60x18 optimalAmountOfB = (UDtokenAInput * convert(currentBalanceOfTokenB)) / convert(currentBalanceOfTokenA);

        //console.log("optimalAmountOfB:", optimalAmountOfB.unwrap());
        //console.log("UDtokenBInput:", UDtokenBInput.unwrap());
        if (optimalAmountOfB <= UDtokenBInput) {
            //optimal amount of B must be at least equal to slippageAmountOfTokenB
            require(optimalAmountOfB >= minimumAmountOfTokenB, "Insufficient Token B Amount");

            return (tokenAInput, convert(optimalAmountOfB));
        } else {
            UD60x18 convertedCurrentBalanceA = convert(currentBalanceOfTokenA);
            UD60x18 optimalAmountofA = (UDtokenBInput * convertedCurrentBalanceA) / convert(currentBalanceOfTokenB);

            //Slippage fee to calculate minimum amount of A doesn't make sense as we have
            // already ensured that there is too much token A

            return (convert(optimalAmountofA), tokenBInput);
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

        uint256 actualADeposited = _newBalanceOfA - _currentBalanceOfA;
        uint256 actualBDeposited = _newBalanceOfB - _currentBalanceOfB;

        bool isFeeOn = _mintFee(_newBalanceOfA, _newBalanceOfB, _totalSupply);

        uint256 LPReward;
        if (_totalSupply == 0) {
            // console.log("entered1");
            // console.log("actualADepositedFirst:", actualADeposited);
            // console.log("actualBDepositedFirst:", actualBDeposited);
            UD60x18 geometricMean = gm(convert(actualADeposited), convert(actualBDeposited));
            //console.log("geometricMean:", geometricMean.unwrap());

            LPReward = convert(geometricMean) - MINIMUM_LIQUIDITY;
            //console.log("First LPReward:", LPReward);
            // we are going to mint the minimum liquidity
            _mint(0x000000000000000000000000000000000000dEaD, MINIMUM_LIQUIDITY);
        } else {
            //console.log("entered2");
            //This is where Uniswap punishes naive Liquidity Providers
            // if the ratio is 50:50,
            // and the provider somehow provides as 90:10
            // in the actual Uniswap contract,
            //they can bypass the Uniswap Router
            // the pool will accept all tokens
            // but will take LP reward of the person as if he put in 10:10 (as of the original ratio)
            // so that is why we take the min of
            // tokensAprovided * totalSupply /tokenAReserve, tokensBprovided * totalSupply/tokenBReserve
            UD60x18 rewardForTokenA =
                convert(actualADeposited).mul(convert(_totalSupply)).div(convert(_currentBalanceOfA));
            UD60x18 rewardForTokenB =
                convert(actualBDeposited).mul(convert(_totalSupply)).div(convert(_currentBalanceOfB));
            //PRb has no min math...?
            //console.log("rewardForTokenA:", convert(rewardForTokenA));
            //console.log("rewardForTokenB:", convert(rewardForTokenB));
            if (rewardForTokenA > rewardForTokenB) {
                LPReward = convert(rewardForTokenB);
            } else {
                LPReward = convert(rewardForTokenA);
            }
        }
        //check that LPReward is not 0
        //TODO: explain why
        //console.log("entered3");
        //console.log("LPRewardAfter3", LPReward);
        require(LPReward > 0, "LPReward cannot be zero");
        _mint(liquidityProvider, LPReward);
        //internal accounting
        internalAccounting(_newBalanceOfA, _newBalanceOfB);

        // check the balances now
        if (isFeeOn) {
            lastSnapshotOfProductOfReserves = balanceOfTokenA * balanceOfTokenB;
        }
        emit AddLiquidity(msg.sender, actualADeposited, actualBDeposited);
    }

    function flashLoan(uint256 amountAOut, uint256 amountBOut, address to, bytes calldata data) external {
        require(amountAOut > 0 || amountBOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (IERC20 _tokenA, IERC20 _tokenB, uint256 _reserveA, uint256 _reserveB) =
            (tokenA, tokenB, balanceOfTokenA, balanceOfTokenB);

        require(address(_tokenA) != to && address(_tokenB) != to, "Invalid to Address");
        require(_reserveA > amountAOut && _reserveB > amountBOut, "Insufficient Reserves/Liquidity");
        //optimistically transfer tokens

        if (amountAOut > 0) {
            _tokenA.safeTransfer(to, amountAOut);
        }
        if (amountBOut > 0) {
            _tokenB.safeTransfer(to, amountBOut);
        }
        //contract implement Interface
        if (data.length > 0) {
            //must implement uniswapCall method
            //
            IUniswapCallee(to).uniswapCall(msg.sender, amountAOut, amountBOut, data);
        }
        uint256 currentBalanceOfA = _tokenA.balanceOf(address(this));
        uint256 currentBalanceOfB = _tokenB.balanceOf(address(this));
        //for learning purposes as ternary operator is long
        bool balanceOfAhasIncreasedAfterLoan = currentBalanceOfA > _reserveA - amountAOut;
        bool balanceOfBhasIncreasedAfterLoan = currentBalanceOfB > _reserveB - amountBOut;
        uint256 amountOfAReturned;
        uint256 amountOfBReturned;
        if (balanceOfAhasIncreasedAfterLoan) {
            //assume oldBalanceBeforeLoan is 1000
            //we loan out 1000,
            // we get back X,
            //assume currentBalance is now 2000
            // X = currentBalance - (1000-1000)
            // X = currentBalance -0
            // X = 2000;

            amountOfAReturned = currentBalanceOfA - (_reserveA - amountAOut);
        }
        if (balanceOfBhasIncreasedAfterLoan) {
            amountOfBReturned = currentBalanceOfB - (_reserveB - amountBOut);
        }
        require(amountOfAReturned > 0 || amountOfBReturned > 0, "Nothing was returned!");

        //Balance x*y=k
        //Okay we want to check the K snapshot of product reserves is either equal or
        //greater after the flash loan
        // IN FACT it needs to be at least equal or greater after accouting the swapFeePercentage
        // of the tokens coming IN
        // In other words, the current Balance must be
        // oldBalanceOfA + amountOfAReturned + (0.3%) * amountOfAReturned
        // oldBalanceOfB + amountOfBReturned + (0.3%) * amountOfBReturned
        // 1000 + 1000 + 3 = 2003 (it needs to be at least 2003)
        uint256 _swapFeePercentage = swapFeePercentageVariable;
        //100.3% of amountOfAReturned
        uint256 tokenABalanceAdjusted = calculateAdjustedBalance(_reserveA, amountOfAReturned, _swapFeePercentage);
        uint256 tokenBBalanceAdjusted = calculateAdjustedBalance(_reserveB, amountOfBReturned, _swapFeePercentage);
        require((tokenABalanceAdjusted * tokenBBalanceAdjusted) > (_reserveA * _reserveB), "Pool decreased!");
        internalAccounting(currentBalanceOfA, currentBalanceOfB);
        //TODO: Resolve Stack Too Deep
        //emit FlashLoan(to, amountAOut, amountOfAReturned, amountBOut, amountOfBReturned);
    }

    function calculateAdjustedBalance(uint256 _reserve, uint256 amountReturned, uint256 _swapFeePercentage)
        internal
        pure
        returns (uint256 adjustedBalance)
    {
        UD60x18 castedSwapFeePercentage = ud(_swapFeePercentage);
        UD60x18 amountInReturnedPlusFee =
            ceil(convert(amountReturned) + convert(amountReturned).mul(castedSwapFeePercentage));
        adjustedBalance = _reserve + convert(amountInReturnedPlusFee);
    }

    /**
     * @dev This function is the remove Liquidity function.
     * It will start at the very beginning of the user journey, so it will include
     * what would normally be in the router
     * slippage will not be considered here because amountAmin and amountBmin would
     * have meant that the possible return amount for tokenA and tokenB has been precalculated before
     * this function's execution.
     * @param liquidityRemover, address ,user that wants to withdraw liquidity
     * @param desiredAmountOfLPTokensToBurn uint256, amount of tokens the user needs to burn
     */
    function removeLiquidity(address liquidityRemover, uint256 desiredAmountOfLPTokensToBurn) external {
        //transfer the LP tokens first
        IERC20 LPToken = IERC20(address(this));

        uint256 previousLPTokenBalance = LPToken.balanceOf(address(this));
        LPToken.safeTransferFrom(liquidityRemover, address(this), desiredAmountOfLPTokensToBurn);
        uint256 amountOfLPTokensToBurn = LPToken.balanceOf(address(this)) - previousLPTokenBalance;

        require(amountOfLPTokensToBurn > 0, "LP Burn cannot be zero");
        //calculate how much liquidity
        uint256 _currentBalanceOfA = balanceOfTokenA;
        uint256 _currentBalanceOfB = balanceOfTokenB;
        uint256 _totalSupply = totalSupply();
        bool isFeeOn = _mintFee(_currentBalanceOfA, _currentBalanceOfB, _totalSupply);

        UD60x18 amountOfTokenAToBeWithdrawn =
            ud(_currentBalanceOfA * amountOfLPTokensToBurn).div(ud(_totalSupply * PRB_MATH_SCALE));
        UD60x18 amountOfTokenBToBeWithdrawn =
            ud(_currentBalanceOfB * amountOfLPTokensToBurn).div(ud(_totalSupply * PRB_MATH_SCALE));

        // console.log("amountOfTokenAToBeWithdrawn:",amountOfTokenAToBeWithdrawn.unwrap());
        // console.log("amountOfTokenBToBeWithdrawn:",amountOfTokenBToBeWithdrawn.unwrap());
        //amount of token to be withdrawn is greater than the balance wtf im using the library wrong

        require(amountOfTokenAToBeWithdrawn > ud(0), "Insuffient LP tokens to burn for A");
        require(amountOfTokenBToBeWithdrawn > ud(0), "Insuffient LP tokens to burn for B");

        //burn
        _burn(address(this), amountOfLPTokensToBurn);
        //send tokens over
        uint256 actualAWithdrawn = amountOfTokenAToBeWithdrawn.unwrap();
        uint256 actualBWithdrawn = amountOfTokenBToBeWithdrawn.unwrap();

        tokenA.safeTransfer(liquidityRemover, actualAWithdrawn);
        tokenB.safeTransfer(liquidityRemover, actualBWithdrawn);

        uint256 newBalanceofA = tokenA.balanceOf(address(this));
        uint256 newBalanceofB = tokenB.balanceOf(address(this));
        //internal accounting
        internalAccounting(newBalanceofA, newBalanceofB);
        if (isFeeOn) {
            lastSnapshotOfProductOfReserves = balanceOfTokenA * balanceOfTokenB;
        }
        emit RemoveLiquidity(msg.sender, actualAWithdrawn, actualBWithdrawn);
    }

    function calculateExactTokensForTokensOut(
        uint256 exactAmountIn,
        uint256 currentReserveOfDesiredToken,
        uint256 currentReserveOfCollateralToken
    ) internal pure returns (uint256 calculatedAmountOut) {
        UD60x18 swapFeePercentage = ud(0.997e18);
        UD60x18 amountInAfterFee = convert(exactAmountIn).mul(swapFeePercentage);
        UD60x18 numerator = amountInAfterFee * convert(currentReserveOfDesiredToken);
        UD60x18 denominator = convert(currentReserveOfCollateralToken) + amountInAfterFee;
        calculatedAmountOut = convert(numerator / denominator); //round down;
    }

    function regularSwapExactTokensForTokens(
        address desiredTokenAddress,
        uint256 exactAmountIn,
        uint256 amountOutMin,
        address swapper
    ) external {
        require(desiredTokenAddress == address(tokenA) || desiredTokenAddress == address(tokenB), "Invalid Token");
        (
            IERC20 desiredToken,
            IERC20 collateralToken,
            uint256 currentReserveOfDesiredToken,
            uint256 currentReserveOfCollateralToken
        ) = desiredTokenAddress == address(tokenA)
            ? (tokenA, tokenB, balanceOfTokenA, balanceOfTokenB)
            : (tokenB, tokenA, balanceOfTokenB, balanceOfTokenA);

        uint256 calculatedAmountOut = calculateExactTokensForTokensOut(
            exactAmountIn, currentReserveOfDesiredToken, currentReserveOfCollateralToken
        );
        require(amountOutMin >= calculatedAmountOut, "Insufficient Amount out");
        collateralToken.safeTransferFrom(swapper, address(this), exactAmountIn);
        desiredToken.safeTransfer(swapper, calculatedAmountOut);
        uint256 newBalanceOfDesiredToken = desiredToken.balanceOf(address(this));
        uint256 newBalanceOfCollateralToken = collateralToken.balanceOf(address(this));

        //update
        require(
            newBalanceOfCollateralToken * newBalanceOfDesiredToken
                >= currentReserveOfDesiredToken * currentReserveOfCollateralToken,
            "Maintain Constant Product Formula K during swap"
        );
        // which one is A, which one is B as its (A,B)
        if (desiredToken == tokenA) {
            internalAccounting(newBalanceOfDesiredToken, newBalanceOfCollateralToken);
        } else {
            internalAccounting(newBalanceOfCollateralToken, newBalanceOfDesiredToken);
        }
        //amount In is taxed at 0.3%
        // UD60x18 swapFeePercentage = ud(0.997e18);
        // UD60x18 amountInAfterFee = convert(exactAmountIn).mul(swapFeePercentage);
        // UD60x18 numerator = amountInAfterFee * convert(currentReserveOfDesiredToken);
        // UD60x18 denominator = convert(currentReserveOfCollateralToken) + amountInAfterFee;

        // uint256 calculatedAmountOut = convert(numerator / denominator); //round down;
    }

    function calculateAmountIn() internal {}

    /**
     * @dev function to swap from tokenA to tokenB and vice versa
     * On each swap, there is a 0.3% fee on tokens coming IN, 0% of tokens
     * going out. It is supposed to handle regular swap and flash swap
     * In the Original Uniswap, only a smart contract can handle call the swap
     * as it did not do the transfer of tokens
     * so we are we going to have a wrapper swap, that does the safetransfer of tokens
     * @param desiredTokenAddress:address, Token they want to swap WITH
     * @param desiredAmountOut: uint256, amount of desired Token
     * @param maxAmountIn: uint256, maximum amount of token they want to swap with
     * @param swapper: address, swapper address
     */
    //How do we know if the swap entails
    //"swapTokensforExactTokens",
    // "swapExactTokensForTokens"
    // we are going to make another method for that
    //Question: In Uniswap, the address argument is named `to`. Why is it not `swapper`
    // Best Guess: Assume we use uniswap the regular way, the 'to' address is the EOA interacting with Uniswap
    // And if for Flash loans -> We need to use Smart Contracts -> address we want the tokens to be in amy not be THAT
    // smart contract. Because a smart contract as discussed could be an arbitrager contract depositing in his Metamask address
    // (EOA)
    function regularSwapTokensForExactTokens(
        address desiredTokenAddress,
        uint256 desiredAmountOut,
        uint256 maxAmountIn,
        address swapper
    ) external {
        //swap cannot occur if there are no reserves
        //desiredAmountOut must be greater than 0
        console.log("desiredAmountOut uint:", desiredAmountOut);

        require(desiredTokenAddress == address(tokenA) || desiredTokenAddress == address(tokenB), "Invalid Token");
        (
            IERC20 desiredToken,
            IERC20 collateralToken,
            uint256 currentReserveOfDesiredToken,
            uint256 currentReserveOfCollateralToken
        ) = desiredTokenAddress == address(tokenA)
            ? (tokenA, tokenB, balanceOfTokenA, balanceOfTokenB)
            : (tokenB, tokenA, balanceOfTokenB, balanceOfTokenA);
        //given an input of desiredAmountOut of desiredToken (Let's say Token A)

        // 1. retrieve the required amount (requiredAmount) of Token B to swap for Token A

        //suppose reserve of tokenA is 100, and tokenB is 200
        // k = 200 * 100 = 20_000
        // now we want to swap X amount of tokenA for exactly 50 tokenB
        // What is X? and we need to swap in X + 0.3%(fees) for 50 tokenB

        // Okay, so we know that the ending reserve for token B is 200-50 = 150
        //I need some way to figure out which is the collateral tokenA or TokenB
        //there should be some core swapping logic of amount out

        // given that K is 20_000, the tokenA needed to be swapped is 20_000 / 150 = 133.333
        // then 133.333 must add another 0.3% fee -> 133.3333 + 0.4 = 133.73
        //  then round UP so X is 134

        //TODO: Set Swap Fees to be configurable
        // Current swap Fee percentage is 0.3%, so multiply k with 100.3%

        UD60x18 swapFeePercentage = ud(1.0003e18);

        //div first

        //getAmountIn

        uint256 numerator = currentReserveOfCollateralToken * desiredAmountOut;

        uint256 denominator = currentReserveOfDesiredToken - desiredAmountOut;

        uint256 numeratorWithSlippageFee = convert(swapFeePercentage.mul(convert(numerator)));

        uint256 amountOfCollateralTokenRequired =
            convert(ceil((convert(numeratorWithSlippageFee) / convert(denominator))));

        console.log("after calc");
        // console.log("amountOfCollateralTokenRequired:", amountOfCollateralTokenRequired);
        // console.log("maxAmountIn:", maxAmountIn);
        require(amountOfCollateralTokenRequired <= maxAmountIn, "Max Amount Limit too low");
        //transfer the tokens
        //sender transfers
        collateralToken.safeTransferFrom(swapper, address(this), amountOfCollateralTokenRequired);
        //we transfer
        desiredToken.safeTransfer(swapper, desiredAmountOut);

        //slippage Fee is applied to output token
        uint256 newBalanceOfDesiredToken = desiredToken.balanceOf(address(this));
        uint256 newBalanceOfCollateralToken = collateralToken.balanceOf(address(this));

        //update
        require(
            newBalanceOfCollateralToken * newBalanceOfDesiredToken
                >= currentReserveOfDesiredToken * currentReserveOfCollateralToken,
            "Maintain Constant Product Formula K during swap"
        );
        // which one is A, which one is B as its (A,B)
        if (desiredToken == tokenA) {
            internalAccounting(newBalanceOfDesiredToken, newBalanceOfCollateralToken);
        } else {
            internalAccounting(newBalanceOfCollateralToken, newBalanceOfDesiredToken);
        }
    }

    /**
     * @dev This function is to do internal accounting of keep tracking reserve0 and reserve1,
     * which is balanceOfTokenA and balanceOfTokenB
     *    @param newBalanceofA uint256, new total amount of Token A in this liquidity pool
     *    @param newBalanceofB uint256, new total amount of Token B in this liquidity pool
     *    is uint256 because tokens are calculated in wei
     */
    //TODO: change back to private
    function internalAccounting(uint256 newBalanceofA, uint256 newBalanceofB) internal {
        //Question: Why does _update in uniswap also take _reserve0, and _reserve1?
        //Best Guess: gas savings, Reading from State Variables multiple times is costly
        // than reading a memory varialbe
        // Uniswap only accesses the state variable to update State ONCE,
        //  memory pointer for that uint256 would do the Math Part just fine

        // Uniswap Original Code
        //  if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
        //     // * never overflows, and + overflow is desired
        //     price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
        //     price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        // }

        //In practice, when you want to calculate a TWAP over an interval,
        // you would need two points in time the beginning and the end of the desired
        // interval

        // In UniswapV2, priceCumulativeLast is always overriden. How can we calculate
        // the TWAP if we only have the latest point in time?
        // We have to store "checkpoints" of price cumulative last somewhere (offchain usually)
        // or emit Events
        uint256 currentTime = block.timestamp;
        uint256 timePassedSinceLiquidityEvent = currentTime - blockTimestampLast;

        //checking if you are a transaction where timePassed is gt 0

        //balanceOfTokenA & balanceOfTokenB is accessing state variable
        //console.log("_updateDebug1");
        if (timePassedSinceLiquidityEvent > 0 && balanceOfTokenA > 0 && balanceOfTokenB > 0) {
            //console.log("_updateDebug2");
            UD60x18 priceOfACL =
                convert(balanceOfTokenA) / convert(balanceOfTokenB) * convert(timePassedSinceLiquidityEvent);
            UD60x18 priceOfBCL =
                convert(balanceOfTokenB) / convert(balanceOfTokenA) * convert(timePassedSinceLiquidityEvent);
            priceOfACumulativeLast += convert(priceOfACL);
            priceOfBCumulativeLast += convert(priceOfBCL);
            //event way
            emit PriceSnapshotTaken(priceOfACumulativeLast, priceOfBCumulativeLast, currentTime);
            //contract variable way
            //but this one is not so good, how to get a good range?
            snapshotMap[currentTime] = SnapshotStruct(balanceOfTokenA, balanceOfTokenB);
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
     *
     */
    //TODO: Change back to private
    function _mintFee(uint256 _newBalanceOfA, uint256 _newBalanceOfB, uint256 _totalSupply)
        internal
        returns (bool isFeeOn)
    {
        console.log("mintFeeEntered");
        //TODO: Add factory contract to include treasury address
        address _feeBeneficiary = feeBeneficiary;
        isFeeOn = feeOn;
        //if fee is on
        if (isFeeOn) {
            console.log("lastSnapshotOfProductOfReserves:", lastSnapshotOfProductOfReserves);
            //and that kLast is not zero
            if (lastSnapshotOfProductOfReserves != 0) {
                //get the geometric mean of the old pool
                console.log("ud(_newBalanceOfA):", ud(_newBalanceOfA).unwrap());
                console.log("ud(_newBalanceOfB):", ud(_newBalanceOfB).unwrap());
                //overflow

                //TODO: old pool gm and new pool gm calculation is wrong
                //to handle overflow for sqrt
                // oldPoolGm: 1500000000000000000000000000000
                // newPoolGm: 1500000000000000000000

                UD60x18 oldPoolGm = sqrt(convert(lastSnapshotOfProductOfReserves));
                //get geometric mean of the new pool

                UD60x18 newPoolGm = gm(convert(_newBalanceOfA), convert(_newBalanceOfB));
                uint256 feesMinted;
                console.log("oldPoolGm:", oldPoolGm.unwrap());
                console.log("newPoolGm:", newPoolGm.unwrap());

                //if the pool DID increase
                if (newPoolGm > oldPoolGm) {
                    console.log("pool did increase");
                    uint256 _mintFeePercentageDenominator = mintFeePercentageDenominator; //gas savings

                    //This formula gives you the accumulated fees between
                    //t1 and t2 as a percentage of the liquidity in the pool at t2
                    //This complicated formula is in Uniswap Whitepaper
                    //https://uniswap.org/whitepaper.pdf
                    // So numerator and Denomintor is just the code version of the
                    // formula in the whitepaper
                    // if 1/6 fees, then its (1/(1/6)-1) = 5
                    // if its 1/3 fees, then its (1/(1/3)-1) = 2
                    feesMinted = calculateFeesMinted(_totalSupply, _mintFeePercentageDenominator, oldPoolGm, newPoolGm);
                    console.log("feesMinted:", feesMinted);
                    if (feesMinted > 0) {
                        _mint(_feeBeneficiary, feesMinted);
                    }
                }
            }
        } else if (lastSnapshotOfProductOfReserves != 0) {
            //set state back to zero
            //refund feature ?
            //So this is not really necessary
            lastSnapshotOfProductOfReserves = 0;
        }
    }

    function calculateFeesMinted(
        uint256 _totalSupply,
        uint256 _mintFeePercentageDenominator,
        UD60x18 oldPoolGm,
        UD60x18 newPoolGm
    ) internal view returns (uint256 feesMinted) {
        UD60x18 mintFeePercentageMultiplier = inv(ud(1e18).div(convert(_mintFeePercentageDenominator))) - ud(1e18);
        UD60x18 numerator = convert(_totalSupply).mul(newPoolGm - oldPoolGm);
        UD60x18 denominator = newPoolGm.mul(mintFeePercentageMultiplier).add(oldPoolGm);
        console.log("numerator:", convert(numerator));
        console.log("denominator:", convert(denominator));

        feesMinted = convert(ceil(numerator.div(denominator)));
    }
}

//damnvulnerable defi problem puppet v2
