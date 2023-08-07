// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MIN_USD = 5e18; // min $5 * 1e18, constant saves gas
    address[] private s_funders;
    mapping(address funder => uint256 ammountFunded) private s_mapAdrsToAmount;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    function fund() public payable {
        // payable < can recieve eth

        // require (getEthFromUsd(msg.value) >= minUsdVal, "didn't send enaugh ETH!"); /// 1 ETH
        require(
            msg.value.getEthFromUsd(s_priceFeed) >= MIN_USD,
            "didn't send enaugh ETH!"
        ); /// 1 ETH
        s_funders.push(msg.sender);
        s_mapAdrsToAmount[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 funLen = s_funders.length;
        for (uint256 fundi = 0; fundi < funLen; fundi++) {
            address tmpa = s_funders[fundi];
            s_mapAdrsToAmount[tmpa] = 0;
        }
        s_funders = new address[](0);
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Send failed, revering!");
    }

    function withdraw() public onlyOwner {
        // reset mapping to 0
        for (uint256 fundi = 0; fundi < s_funders.length; fundi++) {
            address tmpa = s_funders[fundi];
            s_mapAdrsToAmount[tmpa] = 0;
        }

        // reset funderes array
        s_funders = new address[](0);

        // withdraw funds

        // // 1 transfer need to cast to payable first, gas limited, can error and will revert automatically
        // payable(msg.sender).transfer(address(this).balance);

        // // 2 send, gas limited, will return boolean if sucessfull
        // bool isSent = payable(msg.sender).send(address(this).balance);
        // require(isSent, "Send failed, revering!");

        // 3 call
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Send failed, revering!");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "You are not the owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        } // more gas efficient
        _; // _ do the rest of the function code
        // do other stuff after function
    }

    // what happens if someone sends eth to contract directly or send to wrong function
    // special function recieve, fallback()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /** Getter Functions */

    /**
     * @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getMapAdrsToAmount(
        address fundingAddress
    ) public view returns (uint256) {
        return s_mapAdrsToAmount[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
