// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/SpiceRedeemer.sol";
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

contract SpiceRedeemerTest is Test {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    SpiceRedeemer spiceRedeemer;
    FakeERC20 fakeERC20;
    address fakeAddress;

    function setUp() public {
        spiceRedeemer = new SpiceRedeemer();
        cheats.deal(address(spiceRedeemer), 5 ether);
        cheats.prank(address(1));
        fakeERC20 = new FakeERC20(5000000);
        fakeAddress = address(fakeERC20);
        spiceRedeemer.setSpiceTokenAddressREMOVEME(fakeAddress);
        spiceRedeemer.activeToggle();
    }


    function testApproveAndRedeem() public {
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedeemer), 1000000);
        cheats.prank(address(1));
        spiceRedeemer.redeem(1000000);
        //emit log_uint(address(1).balance);
        assertEq(address(1).balance, 0.3 ether);
    }

    function testFailRedeemerInactive() public {
        spiceRedeemer.activeToggle();
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedeemer), 1000000);
        cheats.prank(address(1));
        spiceRedeemer.redeem(1000000);
    }

    function testFailWhitelist() public {
        cheats.prank(address(2));
        fakeERC20.approve(address(spiceRedeemer), 1000000);
        cheats.prank(address(2));
        spiceRedeemer.redeem(1000000);
    }

    function testFailWhitelistRemoval() public {
        cheats.prank(address(1));
        fakeERC20.approve(address(spiceRedeemer), 1000000);
        cheats.prank(address(1));
        spiceRedeemer.redeem(1000000);
        assertEq(address(1).balance, 0.3 ether);
        cheats.prank(address(1));
        spiceRedeemer.redeem(1000000);
    }

    
    function testFailRedeemerOverAmount() public {
        cheats.prank(address(1));
        fakeERC20.transfer(address(spiceRedeemer), 2000000);
        cheats.prank(address(1));
        spiceRedeemer.redeem(2000000);
    }


    function testFailRedeemerNotWhitelisted() public {
        cheats.prank(address(1));
        fakeERC20.transfer(address(2), 1000000);
        cheats.prank(address(2));
        fakeERC20.transfer(address(spiceRedeemer), 1000000);
        cheats.prank(address(2));
        spiceRedeemer.redeem(1000000);
    }

    function testFailOnlyOwner() public {
        cheats.prank(address(1));
        spiceRedeemer.updateSpiceValue(1 ether);
    }

    function testFailFunding() public {
        cheats.deal(address(1), 5 ether);
        cheats.prank(address(1));
        payable(address(spiceRedeemer)).transfer(3 ether);
    }

    

}
