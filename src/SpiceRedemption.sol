// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SpiceRedemption {
    bool active = false;
    uint value = 300000000000 wei;
    address[] public whitelist;
    uint[] public claimedBurnAmount;
    
    //Fake SpiceToken
    //Used for testing
    address spiceTokenAddress = 0x9b6dB7597a74602a5A806E33408e7E2DAFa58193;


    //Real SpiceToken
    //address spiceTokenAddress = 0x9b6dB7597a74602a5A806E33408e7E2DAFa58193;


    //This must be reentrancy protected
    //Also ensure that payments are sent to correct place

    //Receive Payment
    //Burn Spice
    //Transfer Eth To Sender

    receive() external payable {
        //require()
        sendViaCall(payable(msg.sender));
    }

    //function updateWhiteList() onlyOwner flag


    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }


}
