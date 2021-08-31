// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.3;

import "./ERC20.sol";

contract CREDIToken is ERC20 {
    constructor() ERC20("CREDEFI", "CREDI") {
        _mint(msg.sender, 1000000000 * 10 ** 18, 1000, (WALLET FOR ETH), (WALLET FOR CREDI), (WALLET FOR BURN));
    }
}
