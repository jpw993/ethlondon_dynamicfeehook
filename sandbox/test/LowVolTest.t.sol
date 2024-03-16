// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MarketData} from "../src/MarketData.sol";

contract LowVolTest is Test {
    MarketData public marketData;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), 5206590); // 2 Feb 2024
        marketData = new MarketData();
    }

    function testMarketDataLowVol() public view {
        uint256 price = marketData.getEthUsdPrice();
        uint256 vol = marketData.getEthUsdVol();

        assertEq(price, 229953802862);
        assertEq(vol, 32105); // 32.105%
    }
}
