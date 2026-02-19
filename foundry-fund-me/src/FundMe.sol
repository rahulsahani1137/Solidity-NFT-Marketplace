// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PriceConverter, AggregatorV3Interface} from "src/PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18; // 5 USD (with 18 decimals)

    address[] public funders;
    mapping(address funder => uint256 amountFunded)
        public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    function fund() public payable {
        // Convert sent ETH to USD and check if it meets minimum
        require(
            msg.value.getConversionRate() >= MINIMUM_USD,
            "Didn't send enough ETH!"
        );
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getAggregatorVersion() public view returns(uint256) {
        return PriceConverter.getVersion();
    }

    function withdraw() public onlyOwner {
        // resetting the funding amounts for all funders in an array
        for (uint index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);

        // withraw the funds

        // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed!");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed!");
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
