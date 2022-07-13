// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/SpiceRedemption.sol";
import "../src/FakeERC20.sol";
import "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface CheatCodes {
    function prank(address, address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address) external;

    // Sets the *next* call's msg.sender to be the input address
    function assume(bool) external;

    // When fuzzing, generate new inputs if conditional not met
    function deal(address who, uint256 newBalance) external;
    // Sets an address' balance
}

contract SpiceRedemptionTest is Test {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    SpiceRedemption spiceRedemption;
    FakeERC20 fakeERC20;
    address fakeAddress;

    function setUp() public {

        spiceRedemption = new SpiceRedemption();
        cheats.deal(address(spiceRedemption), 5 ether);
        cheats.prank(address(1));
        fakeERC20 = new FakeERC20(5000000);
        fakeAddress = address(fakeERC20);
        spiceRedemption.setSpiceTokenAddress(fakeAddress);
        spiceRedemption.activeToggle();
    }


    function testRedemptionGetSpice() public {
        cheats.prank(address(1));
        fakeERC20.transfer(address(spiceRedemption), 1000000);
        assertEq(fakeERC20.balanceOf(address(spiceRedemption)), 1000000);
        //emit log_uint(fakeERC20.balanceOf(address(spiceRedemption)));
    }


    function testApproveAndRedeem() public {
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedemption), 1000000);
        cheats.prank(address(1));
        spiceRedemption.redeem(1000000);
        //emit log_uint(address(1).balance);
        assertEq(address(1).balance, 0.3 ether);
    }

    function testFailRedemptionInactive() public {
        spiceRedemption.activeToggle();
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedemption), 1000000);
        cheats.prank(address(1));
        spiceRedemption.redeem(1000000);
    }

    function testFailWhitelist() public {
        cheats.prank(address(2));
        fakeERC20.approve(address(spiceRedemption), 1000000);
        cheats.prank(address(2));
        spiceRedemption.redeem(1000000);
    }

    function testFailWhitelistRemoval() public {
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedemption), 1000000);
        cheats.prank(address(1));
        spiceRedemption.redeem(1000000);
        assertEq(address(1).balance, 0.3 ether);
        cheats.prank(address(1));
        spiceRedemption.redeem(1000000);
    }

    
    function testFailRedemptionOverAmount() public {
        cheats.prank(address(1));
        fakeERC20.transfer(address(spiceRedemption), 2000000);
        cheats.prank(address(1));
        spiceRedemption.redeem(2000000);
    }


    function testFailRedemptionNotWhitelisted() public {
        cheats.prank(address(1));
        fakeERC20.transfer(address(2), 1000000);
        cheats.prank(address(2));
        fakeERC20.transfer(address(spiceRedemption), 1000000);
        cheats.prank(address(2));
        spiceRedemption.redeem(1000000);
    }

}
