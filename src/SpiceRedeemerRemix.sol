//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


/// @title SpiceDAO Redeemer
/// @author 0xNotes
/// @notice This contract is used to burn whitelisted users spice for a set value of eth
/// @dev whiteList and claimedBurnAmount must be in same order
contract SpiceRedeemer {
    //GIVE THIS FAKESPICE
    address spiceTokenAddress = 0xFB4a659be55D0A6BC2DD71FcB3cC643F91bE1A35;
    address owner;
    bool internal locked;
    bool active = true;
    uint256 spiceValue = 300000000000 wei;
    address[] public whiteList = [address(1), 0x9b5C1305a13637d473535b4BF306351212A2387d];
    uint256[] public claimedBurnAmount = [1000000, 100000000000000000000];
    address[] public funders;    // Add Other Funders
    address[] public burnList; 
    mapping(address => uint) burnCount;


    constructor() {
        owner = msg.sender;
        funders.push(owner);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Remove Me Before Deploy, strictly for testing
    function setSpiceTokenAddressREMOVEME(address tokenAddress) public onlyOwner {
        spiceTokenAddress = tokenAddress;
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // Underscore used to execute code it modifies.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }


    modifier funderAccounts() {
        require(getFunder(), "Not a funder!");
        _;
    }


    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }


    fallback() external payable {
        require(getFunder() == true, "Not a funder!");
    }

    function getAllowance() public view returns (uint256){
        return ERC20(spiceTokenAddress).allowance(msg.sender, address(this));
    }


    function burn(uint256 amount) public noReentrant{

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
        burnList.push(msg.sender);
        burnCount[msg.sender] = amount;
        require(received, "Failed to Receive $SPICE");
    }


    function isBurnlisted() public view returns (bool){
        for (uint256 i = 0; i < burnList.length; i++) {
            if (burnList[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }


    /// @notice Redeems Eth After Burn!
    function redeem() public noReentrant {
        require(active, "Redemption is not currently available!");
        require(getWhitelisted(), "Not Whitelisted!");
        require(isBurnlisted(), "Havent Burned!");
        uint256 index = getIndex();
        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: ((burnCount[msg.sender] / 1 ether) * spiceValue)
        }("");
        delete whiteList[index];
        require(sent, "Failed to send Ether");
    }


    /// @notice Gets index of user in whitelist. Used also to verify claimedBurnAmount numbers.
    /// @return index The Index of Message Sender, reverts if not whitelisted
    function getIndex() public view returns (uint256 index) {
        require(getWhitelisted(), "Not On Whitelist");
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == msg.sender) {
                return i;
            }
        }
    }


    /// @notice Gets message senders whitelist status.
    /// @return whiteListed True if on whitelist, False if not on whitelist
    function getWhitelisted() public view returns (bool whiteListed) {
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }



    /// @notice Gets message senders funder status.
    /// @return funder True if on funders whitelist, False if not on funders whitelist
    function getFunder() public view returns (bool funder) {
        for (uint256 i = 0; i < funders.length; i++) {
            if (funders[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }


    /// @notice Updates whitelist for future campaigns
    /// @dev Ensure same order as newClaimedBurnAmount and same number of entries
    /// @param newWhitelist The new whitelist for another campaign
    function updateWhitelist(address[] memory newWhitelist) public onlyOwner {
        whiteList = newWhitelist;
    }


    /// @notice Updates Claimed Burn Amount, ensures users cannot liquidate more than they say they will
    /// @dev Ensure same order as newWhiteList and same number of entries
    /// @param newClaimedBurnAmount The new Claimed Burn Amount list for another campaign
    function updateClaimedBurnAmount(uint256[] memory newClaimedBurnAmount)
        public
        onlyOwner
    {
        claimedBurnAmount = newClaimedBurnAmount;
    }


    /// @notice Updates Spice Value, this is the amount we will pay per Spice in ETH
    /// @param newSpiceValue The new price we are willing to pay for Spice in a redemption
    function updateSpiceValue(uint256 newSpiceValue) public onlyOwner {
        spiceValue = newSpiceValue;
    }


    /// @notice Failsafe: Only to be used if someone sends a ton of Spice to the contract accidentally
    /// @param receiver The account who sent us too much spice or accidentally sent us Spice directly
    /// @param amount The amount of Spice we are sending
    function sendSpice(address receiver, uint256 amount) public onlyOwner {
        ERC20(spiceTokenAddress).transfer(receiver, amount);
    }

    /// @notice used to return eth back to multisig wallet.
    //  function returnETH() public onlyOwner {
    //      (bool sent, bytes memory data) = payable(REPLACEWITHMULTISIGADDRESSS).call{
    //          value: address(this).balance }("");
    //      require(sent, "Failed to send Ether");
    //  }


    /// @notice Used to toggle a campaigns active state, will return false if true, true if false
    function activeToggle() public onlyOwner {
        active = !active;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  $$$$$$\            $$\                     $$$$$$$\   $$$$$$\   $$$$$$\  
// $$  __$$\           \__|                    $$  __$$\ $$  __$$\ $$  __$$\ 
// $$ /  \__| $$$$$$\  $$\  $$$$$$$\  $$$$$$\  $$ |  $$ |$$ /  $$ |$$ /  $$ |
// \$$$$$$\  $$  __$$\ $$ |$$  _____|$$  __$$\ $$ |  $$ |$$$$$$$$ |$$ |  $$ |
//  \____$$\ $$ /  $$ |$$ |$$ /      $$$$$$$$ |$$ |  $$ |$$  __$$ |$$ |  $$ |
// $$\   $$ |$$ |  $$ |$$ |$$ |      $$   ____|$$ |  $$ |$$ |  $$ |$$ |  $$ |
// \$$$$$$  |$$$$$$$  |$$ |\$$$$$$$\ \$$$$$$$\ $$$$$$$  |$$ |  $$ | $$$$$$  |
//  \______/ $$  ____/ \__| \_______| \_______|\_______/ \__|  \__| \______/ 
//           $$ |                                                            
//           $$ |                                            REDEEMER                            
//           \__|                                            -0xNotes                
//
////////////////////////////////////////////////////////////////////////////////////////////////////
