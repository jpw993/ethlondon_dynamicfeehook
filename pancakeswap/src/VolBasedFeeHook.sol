// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {ICLDynamicFeeManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLDynamicFeeManager.sol";
import {CLBaseHook} from "./pool-cl/CLBaseHook.sol";

/// @notice VolBasedFeeHook is a contract that sets the fee based on market volatility
contract VolBasedFeeHook is CLBaseHook, ICLDynamicFeeManager {
    using PoolIdLibrary for PoolKey;

    uint256 constant MIN_FEE = 5000; // 0.005%

    constructor(ICLPoolManager _poolManager) CLBaseHook(_poolManager) {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                noOp: false
            })
        );
    }

    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4)
    {
        poolManager.updateDynamicSwapFee(key);
        return this.beforeSwap.selector;
    }

    function getFee(address sender, PoolKey calldata key) external view override returns (uint24) {
        return 500;
    }

    function getFeeImpl(uint256 amt0, uint256 amt1, uint256 volatility, bool tradeReducesGap)
        internal
        pure
        returns (uint256 fee)
    {
        uint256 volume;
        if (amt0 > 0) {
            volume = amt0;
        } else {
            volume = amt1;
        }

        uint256 volume_factor = 5000; // 0.005%
        uint256 volatility_factor = 2700; // 0.0027%
        uint256 trade_reduces_gap_factor = 1;
        fee = MIN_FEE + (volume_factor * (volume ** 15000000) * (volatility_factor * (volatility ** 20000000)));
        // We reduce the fee for when trades bring us further from market because those tend to be more uninformed traders
        if (!tradeReducesGap) {
            fee *= trade_reduces_gap_factor;
        }
        return fee;
    }
}
