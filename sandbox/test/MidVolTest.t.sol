// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MarketData} from "../src/MarketData.sol";

contract MidVolTest is Test {
    MarketData public marketData;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), 5002455); // 1 Jan 2024
        marketData = new MarketData();
    }

    function testMarketDataMidVol() public view {
        uint256 price = marketData.getEthUsdPrice();
        uint256 vol = marketData.getEthUsdVol();

        assertEq(price, 234314470000);
        assertEq(vol, 33857);
    }
}
