// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";

contract VolBasedDynamicFeeHook is BaseHook {
    uint256 constant MIN_FEE = 1000; // 0.1%

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false, // you can use afterInitialize to set the initial swap fee too
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function getVolAndPrice(PoolKey calldata key) public view returns (uint256, uint256) {
        return (100, 100);
    }

    function calculateFee(uint256 volume, uint256 volatility) internal pure returns (uint256 fee) {
        uint256 volume_factor = 500000; // 50%
        uint256 volatility_factor = 2740; // 1/365 = 0.274 %
        // int256 trade_reduces_gap_factor = 1;
        fee = MIN_FEE + ((volume_factor * (volume * ((volume * 3) / 2))) * (volatility_factor * (volatility ** 2)));
        // We reduce the fee for when trades bring us further from market because those tend to be more uninformed traders
        // if (!tradeReducesGap) {
        //     fee *= trade_reduces_gap_factor;
        // }
        return fee;
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4)
    {
        (uint256 volatility,) = getVolAndPrice(key);
        uint256 fee = calculateFee(uint256(swapData.amountSpecified), volatility);
        poolManager.updateDynamicSwapFee(key, 6900);

        return BaseHook.beforeSwap.selector;
    }
}
