// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC20 is ERC20 {
    uint fixedTax = 0;

    constructor() ERC20("TestERC20", "TEST") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }
}