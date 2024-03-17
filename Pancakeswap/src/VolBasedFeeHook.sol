// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@pancakeswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {ICLDynamicFeeManager} from "@pancakeswap/v4-core/src/pool-cl/interfaces/ICLDynamicFeeManager.sol";
import {CLBaseHook} from "./pool-cl/CLBaseHook.sol";
import {MarketDataProvider} from "./MarketDataProvider.sol";

/// @notice VolBasedFeeHook is a contract that sets the fee based on market volatility
contract VolBasedFeeHook is CLBaseHook, ICLDynamicFeeManager {
    using PoolIdLibrary for PoolKey;

    uint256 constant MIN_FEE = 35e23;
    MarketDataProvider immutable marketDataProvider;

    int256 amountSpecified;

    constructor(ICLPoolManager _poolManager, MarketDataProvider _marketDataProvider) CLBaseHook(_poolManager) {
        marketDataProvider = _marketDataProvider;
    }

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

    function beforeSwap(address, PoolKey calldata key, ICLPoolManager.SwapParams calldata swapParams, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4)
    {
        amountSpecified = swapParams.amountSpecified;
        poolManager.updateDynamicSwapFee(key);
        return this.beforeSwap.selector;
    }

    function getFee(address, /*sender*/ PoolKey calldata /*key*/ ) external view override returns (uint24) {
        uint256 volatility = marketDataProvider.getVol();
        uint256 price = marketDataProvider.getPrice();

        return getFeeImpl(abs(amountSpecified), volatility, price);
    }

    function abs(int256 x) private pure returns (uint256) {
        if (x >= 0) {
            return uint256(x);
        }
        return uint256(-x);
    }

    function getFeeImpl(uint256 volume, uint256 volatility, uint256 price) internal pure returns (uint24) {
        uint256 scaled_volume = volume / 150;
        uint256 longterm_eth_volatility = 60;
        uint256 scaled_vol = volatility / longterm_eth_volatility;
        uint256 constant_factor = 2;

        uint256 fee_per_lot = MIN_FEE + (constant_factor * scaled_volume * scaled_vol ** 2);

        return uint24((fee_per_lot / price / 1e10));
    }
}
