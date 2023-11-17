// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/console.sol";
import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {intoUint256} from "@prb/math/ud60x18/Casting.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";
import {gm, sqrt, ceil, inv, floor} from "@prb/math/ud60x18/Math.sol";
import "./UniswapRewardToken.sol";
import {IUniswapCallee} from "./IUniswapCallee.sol";
import {IERC3156FlashLender} from "./interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "./interfaces/IERC3156FlashBorrower.sol";

contract UniswapPair is UniswapRewardToken, IERC3156FlashLender {
    using SafeERC20 for IERC20;

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

    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public balanceOfTokenA;
    uint256 public balanceOfTokenB;

    uint256 public priceOfACumulativeLast;
    uint256 public priceOfBCumulativeLast;

    address public feeBeneficiary;

    address public factory = address(10);

    struct SnapshotStruct {
        uint256 snapshotPriceOfA;
        uint256 snapshotPriceOfB;
    }

    mapping(uint256 snapshotTime => SnapshotStruct) snapshotMap;

    uint256 public blockTimestampLast;

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
        require(newMintFeePercentage != 0, "Cannot be zero");
        require(msg.sender == factory, "Only Factory may call this");
        mintFeePercentageDenominator = newMintFeePercentage;
    }

    function setFeeOn(bool value) external {
        require(msg.sender == factory, "Only Factory may call this");
        feeOn = value;
    }

    function calculateRatio(
        uint256 tokenAInput,
        uint256 tokenBInput,
        uint256 currentBalanceOfTokenA,
        uint256 currentBalanceOfTokenB,
        UD60x18 slippagePercentage
    ) internal pure returns (uint256 refinedTokenA, uint256 refinedTokenB) {
        UD60x18 UDtokenAInput = convert(tokenAInput);
        UD60x18 UDtokenBInput = convert(tokenBInput);

        UD60x18 minimumAmountOfTokenB = UDtokenBInput - slippagePercentage.mul(UDtokenBInput);

        UD60x18 optimalAmountOfB = (UDtokenAInput * convert(currentBalanceOfTokenB)) / convert(currentBalanceOfTokenA);

        if (optimalAmountOfB <= UDtokenBInput) {
            require(optimalAmountOfB >= minimumAmountOfTokenB, "Insufficient Token B Amount");

            return (tokenAInput, convert(optimalAmountOfB));
        } else {
            UD60x18 convertedCurrentBalanceA = convert(currentBalanceOfTokenA);
            UD60x18 optimalAmountofA = (UDtokenBInput * convertedCurrentBalanceA) / convert(currentBalanceOfTokenB);

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
        require(tokenAInput > 0, "Invalid Input");
        require(tokenBInput > 0, "Invalid Input");
        require(slippagePercentage.gt(ud(0)), "Invalid Slippage %");
        uint256 refinedAmountOfTokenA;
        uint256 refinedAmountOfTokenB;

        uint256 _currentBalanceOfA = balanceOfTokenA;
        uint256 _currentBalanceOfB = balanceOfTokenB;

        uint256 _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            refinedAmountOfTokenA = tokenAInput;
            refinedAmountOfTokenB = tokenBInput;
        } else {
            (refinedAmountOfTokenA, refinedAmountOfTokenB) =
                calculateRatio(tokenAInput, tokenBInput, _currentBalanceOfA, _currentBalanceOfB, slippagePercentage);
        }

        tokenA.safeTransferFrom(liquidityProvider, address(this), refinedAmountOfTokenA);
        tokenB.safeTransferFrom(liquidityProvider, address(this), refinedAmountOfTokenB);

        uint256 _newBalanceOfA = tokenA.balanceOf(address(this));
        uint256 _newBalanceOfB = tokenB.balanceOf(address(this));

        uint256 actualADeposited = _newBalanceOfA - _currentBalanceOfA;
        uint256 actualBDeposited = _newBalanceOfB - _currentBalanceOfB;

        bool isFeeOn = _mintFee(_newBalanceOfA, _newBalanceOfB, _totalSupply);

        uint256 LPReward;
        if (_totalSupply == 0) {
            UD60x18 geometricMean = gm(convert(actualADeposited), convert(actualBDeposited));

            LPReward = convert(geometricMean) - MINIMUM_LIQUIDITY;

            _mint(0x000000000000000000000000000000000000dEaD, MINIMUM_LIQUIDITY);
        } else {
            UD60x18 rewardForTokenA =
                convert(actualADeposited).mul(convert(_totalSupply)).div(convert(_currentBalanceOfA));
            UD60x18 rewardForTokenB =
                convert(actualBDeposited).mul(convert(_totalSupply)).div(convert(_currentBalanceOfB));

            if (rewardForTokenA > rewardForTokenB) {
                LPReward = convert(rewardForTokenB);
            } else {
                LPReward = convert(rewardForTokenA);
            }
        }

        require(LPReward > 0, "LPReward cannot be zero");
        _mint(liquidityProvider, LPReward);
        internalAccounting(_newBalanceOfA, _newBalanceOfB);

        if (isFeeOn) {
            lastSnapshotOfProductOfReserves = balanceOfTokenA * balanceOfTokenB;
        }
        emit AddLiquidity(msg.sender, actualADeposited, actualBDeposited);
    }

    function originalFlashLoan(uint256 amountAOut, uint256 amountBOut, address to, bytes calldata data) external {
        require(amountAOut > 0 || amountBOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        (IERC20 _tokenA, IERC20 _tokenB, uint256 _reserveA, uint256 _reserveB) =
            (tokenA, tokenB, balanceOfTokenA, balanceOfTokenB);

        require(address(_tokenA) != to && address(_tokenB) != to, "Invalid to Address");
        require(_reserveA > amountAOut && _reserveB > amountBOut, "Insufficient Reserves/Liquidity");

        if (amountAOut > 0) {
            _tokenA.safeTransfer(to, amountAOut);
        }
        if (amountBOut > 0) {
            _tokenB.safeTransfer(to, amountBOut);
        }
        if (data.length > 0) {
            IUniswapCallee(to).uniswapCall(msg.sender, amountAOut, amountBOut, data);
        }
        uint256 currentBalanceOfA = _tokenA.balanceOf(address(this));
        uint256 currentBalanceOfB = _tokenB.balanceOf(address(this));
        bool balanceOfAhasIncreasedAfterLoan = currentBalanceOfA > _reserveA - amountAOut;
        bool balanceOfBhasIncreasedAfterLoan = currentBalanceOfB > _reserveB - amountBOut;
        uint256 amountOfAReturned;
        uint256 amountOfBReturned;
        if (balanceOfAhasIncreasedAfterLoan) {
            amountOfAReturned = currentBalanceOfA - (_reserveA - amountAOut);
        }
        if (balanceOfBhasIncreasedAfterLoan) {
            amountOfBReturned = currentBalanceOfB - (_reserveB - amountBOut);
        }
        require(amountOfAReturned > 0 || amountOfBReturned > 0, "Nothing was returned!");

        uint256 _swapFeePercentage = swapFeePercentageVariable;
        uint256 tokenABalanceAdjusted = calculateAdjustedBalance(_reserveA, amountOfAReturned, _swapFeePercentage);
        uint256 tokenBBalanceAdjusted = calculateAdjustedBalance(_reserveB, amountOfBReturned, _swapFeePercentage);
        require((tokenABalanceAdjusted * tokenBBalanceAdjusted) > (_reserveA * _reserveB), "Pool decreased!");
        internalAccounting(currentBalanceOfA, currentBalanceOfB);
    }

    function calculateAdjustedBalance(uint256 _reserve, uint256 amountReturned, uint256 _swapFeePercentage)
        internal
        pure
        returns (uint256 adjustedBalance)
    {
        UD60x18 castedSwapFeePercentage = ud(_swapFeePercentage);
        // we want floor because we are rounding in favour of the pool
        // the old snapshot of K needs to be lte to new snapshot of k
        // so since this function calculates the WOULD BE new snapshot of k
        // (given the loan returned + fee)
        // Rounding DOWN would make it such that
        // flash borrowers need to return MORE, hence floor

        UD60x18 amountInReturnedPlusFee =
            floor(convert(amountReturned) + convert(amountReturned).mul(castedSwapFeePercentage));
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
        IERC20 LPToken = IERC20(address(this));
        console.log("desiredAmountOfLPTokensToBurn:", desiredAmountOfLPTokensToBurn);
        console.log("totalSupplybefore", totalSupply());
        uint256 previousLPTokenBalance = LPToken.balanceOf(address(this));
        LPToken.safeTransferFrom(liquidityRemover, address(this), desiredAmountOfLPTokensToBurn);
        console.log("debug1");
        uint256 amountOfLPTokensToBurn = LPToken.balanceOf(address(this)) - previousLPTokenBalance;
        console.log("debug2");
        require(amountOfLPTokensToBurn > 0, "LP Burn cannot be zero");

        uint256 _currentBalanceOfA = balanceOfTokenA;

        uint256 _currentBalanceOfB = balanceOfTokenB;
        uint256 _totalSupply = totalSupply();
        console.log("debug3");
        bool isFeeOn = _mintFee(_currentBalanceOfA, _currentBalanceOfB, _totalSupply);

        //NOT Rounding in favour of the pool
        console.log("debug4");
        UD60x18 amountOfTokenAToBeWithdrawn =
            convert(_currentBalanceOfA * amountOfLPTokensToBurn).div(ud(_totalSupply * PRB_MATH_SCALE));
        console.log("debug5");
        UD60x18 amountOfTokenBToBeWithdrawn =
            convert(_currentBalanceOfB * amountOfLPTokensToBurn).div(ud(_totalSupply * PRB_MATH_SCALE));
        console.log("debug6");
        //require(amountOfTokenAToBeWithdrawn > ud(0), "Insuffient LP tokens to burn for A");
        console.log("debug7");
        //require(amountOfTokenBToBeWithdrawn > ud(0), "Insuffient LP tokens to burn for B");
        console.log("debug8");
        _burn(address(this), amountOfLPTokensToBurn);
        uint256 actualAWithdrawn = convert(amountOfTokenAToBeWithdrawn);
        uint256 actualBWithdrawn = convert(amountOfTokenBToBeWithdrawn);
        console.log("totalSupply:", totalSupply());
        require(actualAWithdrawn > 0, "Insufficient LP tokens to burn for A");
        require(actualBWithdrawn > 0, "Insufficient LP tokens to burn for B");
        tokenA.safeTransfer(liquidityRemover, actualAWithdrawn);
        tokenB.safeTransfer(liquidityRemover, actualBWithdrawn);

        uint256 newBalanceofA = tokenA.balanceOf(address(this));
        uint256 newBalanceofB = tokenB.balanceOf(address(this));
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
        calculatedAmountOut = convert(numerator / denominator);
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

        require(
            newBalanceOfCollateralToken * newBalanceOfDesiredToken
                >= currentReserveOfDesiredToken * currentReserveOfCollateralToken,
            "Maintain Constant Product Formula K during swap"
        );
        if (desiredToken == tokenA) {
            internalAccounting(newBalanceOfDesiredToken, newBalanceOfCollateralToken);
        } else {
            internalAccounting(newBalanceOfCollateralToken, newBalanceOfDesiredToken);
        }
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
    function regularSwapTokensForExactTokens(
        address desiredTokenAddress,
        uint256 desiredAmountOut,
        uint256 maxAmountIn,
        address swapper
    ) external {
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

        UD60x18 swapFeePercentage = ud(1.0003e18);

        uint256 numerator = currentReserveOfCollateralToken * desiredAmountOut;

        uint256 denominator = currentReserveOfDesiredToken - desiredAmountOut;

        uint256 numeratorWithSlippageFee = convert(swapFeePercentage.mul(convert(numerator)));

        uint256 amountOfCollateralTokenRequired =
            convert(ceil((convert(numeratorWithSlippageFee) / convert(denominator))));

        console.log("after calc");
        require(amountOfCollateralTokenRequired <= maxAmountIn, "Max Amount Limit too low");
        collateralToken.safeTransferFrom(swapper, address(this), amountOfCollateralTokenRequired);
        desiredToken.safeTransfer(swapper, desiredAmountOut);

        uint256 newBalanceOfDesiredToken = desiredToken.balanceOf(address(this));
        uint256 newBalanceOfCollateralToken = collateralToken.balanceOf(address(this));

        require(
            newBalanceOfCollateralToken * newBalanceOfDesiredToken
                >= currentReserveOfDesiredToken * currentReserveOfCollateralToken,
            "Maintain Constant Product Formula K during swap"
        );
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
    function internalAccounting(uint256 newBalanceofA, uint256 newBalanceofB) internal {
        uint256 currentTime = block.timestamp;
        uint256 timePassedSinceLiquidityEvent = currentTime - blockTimestampLast;

        if (timePassedSinceLiquidityEvent > 0 && balanceOfTokenA > 0 && balanceOfTokenB > 0) {
            UD60x18 priceOfACL =
                convert(balanceOfTokenA) / convert(balanceOfTokenB) * convert(timePassedSinceLiquidityEvent);
            UD60x18 priceOfBCL =
                convert(balanceOfTokenB) / convert(balanceOfTokenA) * convert(timePassedSinceLiquidityEvent);
            priceOfACumulativeLast += convert(priceOfACL);
            priceOfBCumulativeLast += convert(priceOfBCL);
            emit PriceSnapshotTaken(priceOfACumulativeLast, priceOfBCumulativeLast, currentTime);
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
    function _mintFee(uint256 _newBalanceOfA, uint256 _newBalanceOfB, uint256 _totalSupply)
        internal
        returns (bool isFeeOn)
    {
        console.log("mintFeeEntered");
        address _feeBeneficiary = feeBeneficiary;
        isFeeOn = feeOn;
        if (isFeeOn) {
            console.log("lastSnapshotOfProductOfReserves:", lastSnapshotOfProductOfReserves);
            if (lastSnapshotOfProductOfReserves != 0) {
                console.log("ud(_newBalanceOfA):", ud(_newBalanceOfA).unwrap());
                console.log("ud(_newBalanceOfB):", ud(_newBalanceOfB).unwrap());

                UD60x18 oldPoolGm = sqrt(convert(lastSnapshotOfProductOfReserves));

                UD60x18 newPoolGm = gm(convert(_newBalanceOfA), convert(_newBalanceOfB));
                uint256 feesMinted;
                console.log("oldPoolGm:", oldPoolGm.unwrap());
                console.log("newPoolGm:", newPoolGm.unwrap());

                if (newPoolGm > oldPoolGm) {
                    console.log("pool did increase");
                    uint256 _mintFeePercentageDenominator = mintFeePercentageDenominator;

                    feesMinted = calculateFeesMinted(_totalSupply, _mintFeePercentageDenominator, oldPoolGm, newPoolGm);
                    console.log("feesMinted:", feesMinted);
                    if (feesMinted > 0) {
                        _mint(_feeBeneficiary, feesMinted);
                    }
                }
            }
        } else if (lastSnapshotOfProductOfReserves != 0) {
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

    function flashFee(address token, uint256 amount) external view returns (uint256) {
        require(token == address(tokenA) || token == address(tokenB), "INVALID_TOKEN");
        return _flashFee(amount);
    }

    function _flashFee(uint256 amount) internal view returns (uint256) {
        UD60x18 castedPercentage = ud(swapFeePercentageVariable);
        return convert(convert(amount).mul(castedPercentage));
    }

    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        override
        returns (bool)
    {
        require(token == address(tokenA) || token == address(tokenB), "Unsupported Token");
        require(amount <= _maxFlashLoan(token), "Max Flash loan limit breached");
        uint256 fee = _flashFee(amount);

        IERC20(token).safeTransfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "Flash Lender: Callback failed"
        );

        uint256 adjustTransferAmt = fee + amount;
        IERC20(token).safeTransferFrom(address(receiver), address(this), adjustTransferAmt);
        uint256 newBalanceofA = tokenA.balanceOf(address(this));
        uint256 newBalanceofB = tokenB.balanceOf(address(this));
        internalAccounting(newBalanceofA, newBalanceofB);
        return true;
    }

    function maxFlashLoan(address token) external view returns (uint256) {
        return _maxFlashLoan(token);
    }

    function _maxFlashLoan(address token) internal view returns (uint256 max) {
        max = token == address(tokenA) ? balanceOfTokenA : balanceOfTokenB;
    }
}
