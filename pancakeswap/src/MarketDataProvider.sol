// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

contract MarketDataProvider {
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getVol() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x31D04174D0e1643963b38d87f26b0675Bb7dC96e);
        (, int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getVolDecimals() public view returns (uint8) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x31D04174D0e1643963b38d87f26b0675Bb7dC96e);
        return uint8(priceFeed.decimals());
    }
}

// 3704796033910000000000
