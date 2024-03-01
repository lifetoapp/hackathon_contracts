// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interface/IERC20Mintable.sol";

contract TestERC20 is IERC20Mintable, ERC20 {
    uint fixedTax = 0;

    constructor() ERC20("TestERC20", "TEST") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint amount) external {
        _mint(to, amount);
    }

    function selfMint(uint amount) external {
        _mint(_msgSender(), amount);
    }
}