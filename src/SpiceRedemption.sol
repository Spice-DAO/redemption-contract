// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract SpiceRedemption {
    bool internal locked;
    bool active = false;
    uint256 spiceValue = 300000000000 wei;
    address[] public whiteList = [address(1)];
    uint256[] public claimedBurnAmount = [1000000];
    address owner;

    //Add Other Funders
    address[] public funders = [owner];

    mapping(address => uint256) public approvedAmount;

    //Fake SpiceToken
    //Used for testing
    address spiceTokenAddress = 0x9b6dB7597a74602a5A806E33408e7E2DAFa58193;

    constructor() {
        // msg provides details about the message that's sent to the contract
        // msg.sender is contract caller (address of contract creator)
        owner = msg.sender;
    }

    //Users approves a transfer from them to us
    //We have them call a redeem that gives their tokens to us
    //After we send eth

    //Real SpiceToken
    //address spiceTokenAddress = 0x9b6dB7597a74602a5A806E33408e7E2DAFa58193;

    //This must be reentrancy protected
    //Also ensure that payments are sent to correct place

    //Receive Payment
    //Burn Spice
    //Transfer Eth To Sender

    //Remove Me For Deploy
    function setSpiceTokenAddress(address tokenAddress) public {
        spiceTokenAddress = tokenAddress;
    }

    //Underscore used to execute code it modifies.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier funderAccounts() {
        require(getFunder() == true, "Not a funder!");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {
        require(getFunder() == true, "Not a funder!");

    }

    //Must approve tokens for the whitelisted or less than amount first
    function redeem(uint256 amount) public payable noReentrant {
        require(active, "Redemption is not currently available!");
        require(getWhitelisted(), "Not Whitelisted!");
        uint256 index = getIndex();
        require(
            amount <= claimedBurnAmount[index],
            "Amount Greater than Claimed Burn Amount"
        );
        bool received = ERC20(spiceTokenAddress).transferFrom(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            amount
        );
        require(received, "Failed to Receive $SPICE");
        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: amount * spiceValue
        }("");
        require(sent, "Failed to send Ether");
        //sendViaCall(payable(msg.sender), (amount * spiceValue));
        delete claimedBurnAmount[index];
        delete whiteList[index];
    }

    function getIndex() public view returns (uint256 index) {
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == msg.sender) {
                return i;
            }
        }
    }

    function getWhitelisted() public view returns (bool whiteListed) {
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function getFunder() public view returns (bool funder) {
        for (uint256 i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function updateWhitelist(address[] memory newWhitelist) public onlyOwner {
        whiteList = newWhitelist;
    }

    function updateClaimedBurnAmount(uint256[] memory newClaimedBurnAmount)
        public
        onlyOwner
    {
        claimedBurnAmount = newClaimedBurnAmount;
    }

    function updateSpiceValue(uint256 newSpiceValue) public onlyOwner {
        spiceValue = newSpiceValue;
    }

    //Only to be used if someone sends a ton of spice to the contract accidentally
    function sendSpice(address receiver, uint256 amount) public onlyOwner {
        ERC20(spiceTokenAddress).transfer(receiver, amount);
    }

    // function returnETH() public onlyOwner {
    //     (bool sent, bytes memory data) = payable(REPLACEWITHMULTISIGADDRESSS).call{
    //         value: address(this).balance }("");
    //     require(sent, "Failed to send Ether");
    // }

    function activeToggle() public onlyOwner {
        active = !active;
    }
}
