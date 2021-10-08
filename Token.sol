// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.9;

import "./ERC20.sol";

contract CREDIToken is ERC20 {
    constructor()
        ERC20(
            "Credi",
            "CREDI",
            0x0000000000000000000000000000000000000000,
            0x0000000000000000000000000000000000000000
        )
    {
        uint8 decimals = 18;
        _mint(150000000 * 10**decimals, decimals);
    }
}
