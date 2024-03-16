// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import {MarketData} from "../src/MarketData.sol";

contract MarketDataTest is Test {
    MarketData public marketData;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        MarketData marketData = new MarketData(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        vm.stopBroadcast();
        return marketData;
    }

    function testAggregatorVersion() public {
        uint256 version = marketData.getVersion();
        console.log("Price Feed Aggregator version: ", version);
        assertEq(version, 4);
    }
}
