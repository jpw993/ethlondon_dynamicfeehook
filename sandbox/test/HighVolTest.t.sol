// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MarketData} from "../src/MarketData.sol";

contract highVolTest is Test {
    MarketData public marketData;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"), 5062165); // 10 Jan 2024
        marketData = new MarketData();
    }

    function testMarketDataHighVol() public view {
        uint256 price = marketData.getEthUsdPrice();
        uint256 vol = marketData.getEthUsdVol();

        assertEq(price, 251724564685);
        assertEq(vol, 102205); // 102.205%
    }
}
