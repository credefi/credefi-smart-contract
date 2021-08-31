// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.3;

abstract contract Owner {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev Transfer ownership.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    /**
     * @dev Returns owner address.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function getOwner() internal view returns (address) {
        return _owner;
    }
}
