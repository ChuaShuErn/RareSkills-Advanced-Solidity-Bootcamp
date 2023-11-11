// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {UD60x18, ud} from "@prb/math/UD60x18.sol";
import {UniswapPair} from "../src/UniswapPair.sol";

contract UniswapPairHarness is UniswapPair {
    constructor(address _tokenA, address _tokenB, address _feeBeneficiary)
        UniswapPair(_tokenA, _tokenB, _feeBeneficiary)
    {}

    function calculateRatio_harness(
        uint256 tokenAInput,
        uint256 tokenBInput,
        uint256 currentBalanceOfTokenA,
        uint256 currentBalanceOfTokenB,
        UD60x18 slippagePercentage
    ) external view returns (uint256 refinedTokenA, uint256 refinedTokenB) {
        return
            calculateRatio(tokenAInput, tokenBInput, currentBalanceOfTokenA, currentBalanceOfTokenB, slippagePercentage);
    }

    function _mintFee_harness(uint256 _newBalanceOfA, uint256 _newBalanceOfB, uint256 _totalSupply)
        public
        returns (bool isFeeOn)
    {
        isFeeOn = _mintFee(_newBalanceOfA, _newBalanceOfB, _totalSupply);
    }

    function internalAccounting_harness(uint256 newBalanceofA, uint256 newBalanceofB) external {
        return internalAccounting(newBalanceofA, newBalanceofB);
    }

    function calculateFeesMinted_harness(
        uint256 _totalSupply,
        uint256 _mintFeePercentageDenominator,
        UD60x18 oldPoolGm,
        UD60x18 newPoolGm
    ) external view returns (uint256) {
        return calculateFeesMinted(_totalSupply, _mintFeePercentageDenominator, oldPoolGm, newPoolGm);
    }
}
