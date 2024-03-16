// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MarketData} from "../src/MarketData.sol";

contract DeployMarketData is Script {
    function run() external {
        vm.startBroadcast();
        new MarketData();
        vm.stopBroadcast();
    }
}
