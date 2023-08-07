// SPDX-License-Identifier: MIT

// 1. deploy mocks when on local anvil
// 2. keey track of contract address acros different chains
// Seploia ETH/USD
// Mainnet ETH/USD

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetwrokConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    uint256 public constant SEPOLIA_CHAIN_ID = 111155111;
    uint256 public constant MAINENT_CHAIN_ID = 1;

    struct NetwrokConfig {
        address priceFeed;
    }

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            // local anvil
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == MAINENT_CHAIN_ID) {
            // mainnet
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            // anvil
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetwrokConfig memory) {
        // ETH price feed address
        NetwrokConfig memory sepoliaConfig = NetwrokConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetwrokConfig memory) {
        // ETH price feed address
        NetwrokConfig memory sepoliaConfig = NetwrokConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetwrokConfig memory) {
        // check to see if already deployed
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // deploy mocks
        // return mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        NetwrokConfig memory anvilConfig = NetwrokConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
