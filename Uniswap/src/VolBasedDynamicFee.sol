// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/BaseHook.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {MarketDataProvider} from "./MarketDataProvider.sol";

contract VolBasedDynamicFeeHook is BaseHook {
    uint256 constant MIN_FEE = 35e23;

    MarketDataProvider immutable marketDataProvider;

    constructor(IPoolManager _poolManager, MarketDataProvider _marketDataProvider) BaseHook(_poolManager) {
        marketDataProvider = _marketDataProvider;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
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

    function getVolatility() public view returns (uint256) {
        return marketDataProvider.getEthUsdVol();
    }

    function getPrice() public view returns (uint256) {
        return marketDataProvider.getEthUsdPrice();
    }

    function calculateFee(uint256 volume, uint256 volatility, uint256 price) internal pure returns (uint24) {
        uint256 scaled_volume = volume / 150;
        uint256 longterm_eth_volatility = 60;
        uint256 scaled_vol = volatility / longterm_eth_volatility;
        uint256 constant_factor = 2;

        uint256 fee_per_lot = MIN_FEE + (constant_factor * scaled_volume * scaled_vol ** 2);

        return uint24((fee_per_lot / price / 1e10));
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function beforeSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata swapData, bytes calldata)
        external
        override
        returns (bytes4)
    {
        uint256 volatility = getVolatility();
        uint256 price = getPrice();
        uint24 fee = calculateFee(abs(swapData.amountSpecified), volatility, price);
        poolManager.updateDynamicSwapFee(key, fee);

        return BaseHook.beforeSwap.selector;
    }

    function getFee(int256 amt) external view returns (uint24) {
        uint256 volatility = getVolatility();
        uint256 price = getPrice();
        return calculateFee(abs(amt), volatility, price);
    }
}
