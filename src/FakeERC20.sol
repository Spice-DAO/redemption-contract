pragma solidity ^0.8.13;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract FakeERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("FakeSpice", "FSP") {
        _mint(msg.sender, initialSupply);
    }
}