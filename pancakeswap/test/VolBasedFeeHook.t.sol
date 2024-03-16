// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {VolBasedFeeHook} from "../src/VolBasedFeeHook.sol";
import {CLTestUtils} from "./pool-cl/utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";

import {FeeLibrary} from "@pancakeswap/v4-core/src/libraries/FeeLibrary.sol";

contract VolBasedFeeHookTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    VolBasedFeeHook volBasedHook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    address alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));

        (currency0, currency1) = deployContractsWithEthUsdTokens();
        volBasedHook = new VolBasedFeeHook(poolManager);

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: volBasedHook,
            poolManager: poolManager,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG,
            // tickSpacing: 10
            parameters: bytes32(uint256(volBasedHook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1000 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1000 ether);
        addLiquidity(key, 1000 ether, 1000 ether, -60, 60);

        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();
    }

    function _swap() internal returns (uint256 amtOut) {
        MockERC20(Currency.unwrap(currency0)).mint(address(alice), 1 ether);

        vm.prank(address(alice), address(alice));

        amtOut = swapRouter.exactInputSingle(
            ICLSwapRouterBase.V4CLExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                recipient: address(this),
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            }),
            block.timestamp
        );
    }

    function testHighVol() public {
        uint256 amtOut = _swap();

        assertEq(amtOut, 999497007648608879);
    }
}