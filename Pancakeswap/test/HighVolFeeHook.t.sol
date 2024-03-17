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

contract HighVolTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    VolBasedFeeHook volBasedHook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    address alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), 5062165); // 10 Jan 2024
        assertEq(block.number, 5062165);

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

    function testHighVolLowAmt() public {
        // Arrange
        uint128 amtIn = uint128(10 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 1544); // 0.1544%
        assertEq(amtOut, 9979700594420733265);
    }

    function testHighVolMidAmt() public {
        // Arrange
        uint128 amtIn = uint128(150 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 3694); // 0.3694%
        assertEq(amtOut, 148364588143595518015);
    }

    function testHighVolHighAmt() public {
        // Arrange
        uint128 amtIn = uint128(300 ether);

        // Act
        uint256 amtOut = _swap(amtIn);
        uint24 fee = volBasedHook.getFee(address(this), key);

        // Assert
        assertEq(fee, 5998); // 0.5998%
        assertEq(amtOut, 293926118931424146658);
    }
}
