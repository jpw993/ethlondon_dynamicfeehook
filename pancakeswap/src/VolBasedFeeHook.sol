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
}
