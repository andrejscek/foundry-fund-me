// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VAL = 0.1 ether;
    uint256 constant START_BAL = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        fundMe = new DeployFundMe().run();
        vm.deal(USER, START_BAL);
    }

    function testMinDollarIsFiveUsd() public {
        assertEq(fundMe.MIN_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDatatStructure() public user_funded {
        uint256 amountFunded = fundMe.getMapAdrsToAmount(USER);
        assertEq(amountFunded, SEND_VAL);
    }

    function testAddFunderToArrayFunders() public user_funded {
        address funder1 = fundMe.getFunder(0);
        assertEq(funder1, USER);

        hoax(address(1), START_BAL);
        fundMe.fund{value: SEND_VAL}();
        assertEq(fundMe.getFunder(1), address(1));
    }

    function testOnlyOwnerCanWithdraw() public user_funded {
        vm.expectRevert(); //ignores vm., next transaction only
        vm.prank(USER);
        fundMe.withdraw();
    }

    modifier user_funded() {
        fundWithUser(USER);
        _;
    }

    function fundWithUser(address _user) internal {
        vm.prank(_user);
        fundMe.fund{value: SEND_VAL}();
    }

    function testWithdrawWithSingleFunder() public user_funded {
        // Arrange
        address owner = fundMe.getOwner();
        uint256 startBal = owner.balance;

        // Act
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(owner);
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log("gasUsed", gasUsed);

        // Assert
        uint256 endingBal = owner.balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(endingBal - startBal, SEND_VAL);
    }

    function testWithdrawFromMultipleFunders() public user_funded {
        // Arrange
        address owner = fundMe.getOwner();
        uint256 startBal = owner.balance;
        uint160 numberOfFunders = 10;
        uint160 startingFunderIdx = 1;
        for (uint160 i = startingFunderIdx; i < numberOfFunders; i++) {
            hoax(address(i), START_BAL);
            fundMe.fund{value: SEND_VAL}();
        }

        // Act
        vm.prank(owner);
        fundMe.withdraw();

        // Assert
        uint256 endingBal = owner.balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(endingBal - startBal, numberOfFunders * SEND_VAL);
    }

    function testCheaperWithdrawFromMultipleFunders() public user_funded {
        // Arrange
        address owner = fundMe.getOwner();
        uint256 startBal = owner.balance;
        uint160 numberOfFunders = 10;
        uint160 startingFunderIdx = 1;
        for (uint160 i = startingFunderIdx; i < numberOfFunders; i++) {
            hoax(address(i), START_BAL);
            fundMe.fund{value: SEND_VAL}();
        }

        // Act
        vm.prank(owner);
        fundMe.cheaperWithdraw();

        // Assert
        uint256 endingBal = owner.balance;
        assertEq(address(fundMe).balance, 0);
        assertEq(endingBal - startBal, numberOfFunders * SEND_VAL);
    }
}
