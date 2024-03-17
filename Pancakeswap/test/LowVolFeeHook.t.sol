// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "@pancakeswap/v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "@pancakeswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@pancakeswap/v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {CLTestUtils} from "./pool-cl/utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "@pancakeswap/v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "@pancakeswap/v4-core/src/types/PoolId.sol";
import {ICLSwapRouterBase} from "@pancakeswap/v4-periphery/src/pool-cl/interfaces/ICLSwapRouterBase.sol";
import {FeeLibrary} from "@pancakeswap/v4-core/src/libraries/FeeLibrary.sol";

import {MarketDataProvider} from "../src/MarketDataProvider.sol";
import {VolBasedFeeHook} from "../src/VolBasedFeeHook.sol";

contract LowVolTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    VolBasedFeeHook volBasedHook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    address alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), 5384450); // 2 Feb 2024
        assertEq(block.number, 5384450);

        (currency0, currency1) = deployContractsWithEthUsdTokens();
        volBasedHook = new VolBasedFeeHook(poolManager, new MarketDataProvider());

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: volBasedHook,
            poolManager: poolManager,
            fee: FeeLibrary.DYNAMIC_FEE_FLAG,
            parameters: bytes32(uint256(volBasedHook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1000 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1000 ether);
        addLiquidity(key, 1000 ether, 1000 ether, -1000, 1000);

        vm.startPrank(alice);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
        vm.stopPrank();
    }

    function _swap(uint128 amountIn) internal returns (uint256 amtOut) {
        MockERC20(Currency.unwrap(currency0)).mint(address(alice), 1000 ether);

        vm.prank(address(alice), address(alice));

        amtOut = swapRouter.exactInputSingle(
            ICLSwapRouterBase.V4CLExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                recipient: address(this),
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            }),
            block.timestamp
        );
    }

    function testLowVolLowAmt() public {
        // Arrange
        uint128 amtIn = uint128(1 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 1034); // 0.1034%
        assertEq(amtOut, 998917334973762125);
    }

    function testLowVolMidAmt() public {
        // Arrange
        uint128 amtIn = uint128(15 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 1224); // 0.1224%
        assertEq(amtOut, 14970701992238324488);
    }

    function testLowVolHighAmt() public {
        // Arrange
        uint128 amtIn = uint128(30 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 1426); // 0.1426%
        assertEq(amtOut, 29913517558636636950);
    }
}
