// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MarketData} from "../src/MarketData.sol";

contract MarketDataTest is Test {
    MarketData public marketData;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        marketData = new MarketData();
    }

    function testAggregatorVersion() public view {
        uint256 version = marketData.getVersion();
        console.log("Price Feed Aggregator version: ", version);
        assertEq(version, 4);
    }
}
