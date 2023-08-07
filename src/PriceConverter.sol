// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getLatestPriceAndTs(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256, uint256) {
        (, int256 answer, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        // need to * 1e10 to get the correct value
        return (uint256(answer * 1e10), updatedAt);
    }

    function getEthFromUsd(
        uint256 ethAm,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (uint256 ethPrice, ) = getLatestPriceAndTs(priceFeed);
        uint256 inUsd = (ethPrice * ethAm) / 1e18;
        return inUsd;
    }

    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        return priceFeed.version();
    }
}
