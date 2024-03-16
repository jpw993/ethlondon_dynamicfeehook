// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";

contract VolBasedDynamicFeeHook is BaseHook {

    uint24 fee;

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

    function setDynamicFee(PoolKey calldata key) public {
        poolManager.updateDynamicSwapFee(key, fee);
    }

    function getVolAndPrice(PoolKey calldata key) public view returns (int256, uint256){
        return (100, 100);
    }

    function setFee(IPoolManager.SwapParams calldata swapData, int256 volatility, uint256 marketPrice) internal
    {
        fee = 6900;
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4)
    {
        key.fee;
        int256 dx = swapData.amountSpecified;

        (int256 volatility, uint256 marketPrice) = getVolAndPrice(key);

        setFee(swapData, volatility, marketPrice);
        setDynamicFee(key);

        return BaseHook.beforeSwap.selector;
    }
}
