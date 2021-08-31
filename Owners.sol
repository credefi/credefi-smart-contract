// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.7;

abstract contract Owners {
    struct TransactionIncreaseSupply {
        bool executed;
        uint256 increase;
        uint256 index;
        string description;
        uint256 time;
    }

    struct TransactionDecreaseSupply {
        bool executed;
        uint256 decrease;
        uint256 index;
        string description;
        uint256 time;
    }

    struct Transaction {
        bool executed;
        address value;
        uint256 index;
        string description;
        uint256 time;
    }

    // Increase supply variables
    uint256 internal increaseSupplyIndex = 0;
    mapping(uint256 => address[]) public increaseSupplyConfirmations;
    mapping(uint256 => TransactionIncreaseSupply)
        public increaseSupplyTransactions;

    TransactionIncreaseSupply[] public nonConfirmedIncreaseSupplyTransactions;

    // Decrease supply variables
    uint256 internal decreaseSupplyIndex = 0;
    mapping(uint256 => address[]) public decreaseSupplyConfirmations;
    mapping(uint256 => TransactionDecreaseSupply)
        public decreaseSupplyTransactions;

    TransactionDecreaseSupply[] public nonConfirmedDecreaseSupplyTransactions;

    //Change receiver variables
    uint256 internal changeReceiverIndex = 0;
    mapping(uint256 => address[]) public changeReceiverConfirmations;
    mapping(uint256 => Transaction) public changeReceiverTransactions;

    Transaction[] public nonConfirmedChangeReceiverTransactions;

    //Add owner variables
    uint256 internal addOwnerIndex = 0;
    mapping(uint256 => address[]) public addOwnerConfirmations;
    mapping(uint256 => Transaction) public addOwnerTransactions;

    Transaction[] public nonConfirmedAddOwnerTransactions;

    //Remove owner variables
    uint256 internal removeOwnerIndex = 0;
    mapping(uint256 => address[]) public removeOwnerConfirmations;
    mapping(uint256 => Transaction) public removeOwnerTransactions;

    Transaction[] public nonConfirmedRemoveOwnerTransactions;

    //Owners
    address[] private _owners;
    mapping(address => bool) public isOwner;

    address private _receiver;

    /**
     * @dev Modifier checks sender is owner.
     */
    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    constructor() {
        address addr = address(msg.sender);
        _owners = [addr];
        isOwner[msg.sender] = true;
        _receiver = addr;
    }

    /**
     * @dev Returns owners.
     */
    function owners() internal view returns (address[] memory o) {
        return _owners;
    }

    /**
     * @dev Returns owners to WEB3.
     */
    function getOwners() external view returns (address[] memory o) {
        return _owners;
    }

    /**
     * @dev Returns receiver address.
     */
    function receiver() internal view returns (address) {
        return _receiver;
    }

    /**
     * @dev Returns receiver address to WEB3.
     */
    function getReceiver() external view virtual returns (address) {
        return _receiver;
    }

    /**
     * @dev Returns increaseSupply transaction.
     */
    function getIncreaseSupplyTransaction(uint256 index)
        external
        view
        virtual
        returns (TransactionIncreaseSupply memory transaction)
    {
        return increaseSupplyTransactions[index];
    }

    /**
     * @dev Returns increase supply transaction confirmations.
     */
    function getIncreaseSupplyTransactionConfirmations(uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        return increaseSupplyConfirmations[index];
    }

    /**
     * @dev Returns Non confirmed increase supply transactions.
     */
    function getNonConfirmedIncreaseSupplyTransactions()
        external
        view
        virtual
        returns (TransactionIncreaseSupply[] memory transaction)
    {
        return nonConfirmedIncreaseSupplyTransactions;
    }

    /**
     * @dev Returns transaction decrease supply.
     */
    function getDecreaseSupplyTransaction(uint256 index)
        external
        view
        virtual
        returns (TransactionDecreaseSupply memory transaction)
    {
        return decreaseSupplyTransactions[index];
    }

    /**
     * @dev Returns decrease supply transaction confirmations.
     */
    function getDecreaseSupplyTransactionConfirmations(uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        return decreaseSupplyConfirmations[index];
    }

    /**
     * @dev Returns Non confirmed increase supply transactions WEB3.
     */
    function getNonConfirmedDecreaseSupplyTransactions()
        external
        view
        virtual
        returns (TransactionDecreaseSupply[] memory transaction)
    {
        return nonConfirmedDecreaseSupplyTransactions;
    }

    /**
     * @dev Change receiver
     *
     * - `addr` sets _receiver.
     */
    function changeReceiver(address addr) internal onlyOwners {
        require(addr != address(0), "Address is invalid!");
        _receiver = addr;
    }

    /**
     * @dev Create change receiver transaction
     *
     * - `address` new address.
     * - `description` some information about event.
     */
    function changeReceiverTransaction(address addr, string memory description)
        external
        payable
        onlyOwners
        returns (Transaction memory t)
    {
        require(addr != address(0), "Address is invalid!");
        uint256 index = changeReceiverIndex;
        changeReceiverTransactions[index] = Transaction(
            false,
            addr,
            index,
            description,
            block.timestamp
        );
        changeReceiverConfirmations[index].push(msg.sender);
        nonConfirmedChangeReceiverTransactions.push(
            changeReceiverTransactions[index]
        );
        changeReceiverIndex++;
        return changeReceiverTransactions[index];
    }

    /**
     * @dev Confirm change receiver transaction
     *
     * - `index` index of transaction.
     */
    function changeReceiverConfirmTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            changeReceiverConfirmations[index].length > 0,
            "Transaction not exists"
        );
        bool exists = false;
        address[] memory addrs = changeReceiverConfirmations[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == msg.sender) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        changeReceiverConfirmations[index].push(msg.sender);
        changeReceiverTransactions[index].time = block.timestamp;
        return true;
    }

    /**
     * @dev Execute change receiver transaction
     *
     * - `index` index of transaction.
     */
    function changeReceiverExecute(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            changeReceiverConfirmations[index].length >= owners().length,
            "Transaction not confirmed!"
        );

        changeReceiverRemoveExecute(index);
        changeReceiver(changeReceiverTransactions[index].value);
        return true;
    }

    /**
     * @dev Delete change receiver transaction
     *
     * - `index` index of transaction.
     */
    function changeReceiverRemove(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            changeReceiverConfirmations[index].length >= 0,
            "Transaction not confirmed!"
        );

        return changeReceiverRemoveExecute(index);
    }

    /**
     * @dev Delete change receiver
     *
     * - `index` index of transaction.
     */
    function changeReceiverRemoveExecute(uint256 index)
        internal
        onlyOwners
        returns (bool b)
    {
        Transaction memory t = changeReceiverTransactions[index];

        require(t.executed == false, "Transaction has been executed!");

        changeReceiverTransactions[index].executed = true;

        for (
            uint256 i = 0;
            i < nonConfirmedChangeReceiverTransactions.length;
            i++
        ) {
            Transaction memory tr = nonConfirmedChangeReceiverTransactions[i];
            if (tr.index == index) {
                nonConfirmedChangeReceiverTransactions[
                    i
                ] = nonConfirmedChangeReceiverTransactions[
                    nonConfirmedChangeReceiverTransactions.length - 1
                ];
                nonConfirmedChangeReceiverTransactions.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Returns Change receiver transaction.
     */
    function getChangeReceiverTransaction(uint256 index)
        external
        view
        virtual
        returns (Transaction memory transaction)
    {
        return changeReceiverTransactions[index];
    }

    /**
     * @dev Returns Change receiver transaction confirmations.
     */
    function getChangeReceiverTransactionConfirmations(uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        return changeReceiverConfirmations[index];
    }

    /**
     * @dev Returns Non confirmed change receiver transactions.
     */
    function getNonConfirmedChangeReceiverTransactions()
        external
        view
        virtual
        returns (Transaction[] memory transaction)
    {
        return nonConfirmedChangeReceiverTransactions;
    }

    /**
     * @dev Add new owner to list.
     *
     * - `addr` addrees pushed in array.
     */
    function addOwner(address addr) internal onlyOwners {
        require(addr != address(0), "Address is invalid!");
        require(isOwner[addr] == false, "Owner exists!");

        bool exists = false;

        for (uint256 i = 0; i < _owners.length; i++) {
            address a = _owners[i];

            if (addr == a) {
                exists = true;
                break;
            }
        }

        require(exists == false, "Owner exists!");

        isOwner[addr] = true;
        _owners.push(addr);
    }

    /**
     * @dev Create add owner transaction
     *
     * - `addr` new owner.
     * - `description` some information about event.
     */
    function addOwnerTransaction(address addr, string memory description)
        external
        payable
        onlyOwners
        returns (Transaction memory t)
    {
        require(addr != address(0), "Address is invalid!");
        uint256 index = addOwnerIndex;
        addOwnerTransactions[index] = Transaction(
            false,
            addr,
            index,
            description,
            block.timestamp
        );
        addOwnerConfirmations[index].push(msg.sender);
        nonConfirmedAddOwnerTransactions.push(addOwnerTransactions[index]);
        addOwnerIndex++;
        return addOwnerTransactions[index];
    }

    /**
     * @dev Confirm add owner transaction
     *
     * - `index` index of transaction.
     */
    function addOwnerConfirmTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            addOwnerConfirmations[index].length > 0,
            "Transaction not exists"
        );
        bool exists = false;
        address[] memory addrs = addOwnerConfirmations[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == msg.sender) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        addOwnerConfirmations[index].push(msg.sender);
        addOwnerTransactions[index].time = block.timestamp;
        return true;
    }

    /**
     * @dev Execute add owner transaction
     *
     * - `index` index of transaction.
     */
    function addOwnerExecute(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            addOwnerConfirmations[index].length >= owners().length,
            "Transaction not confirmed!"
        );

        addOwnerRemoveExecute(index);
        addOwner(addOwnerTransactions[index].value);
        return true;
    }

    /**
     * @dev Remove add owner transaction
     *
     * - `index` index of transaction.
     */
    function addOwnerRemove(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            addOwnerConfirmations[index].length >= 0,
            "Transaction not confirmed!"
        );

        return addOwnerRemoveExecute(index);
    }

    /**
     * @dev Remove add owner
     *
     * - `index` index of transaction.
     */
    function addOwnerRemoveExecute(uint256 index)
        internal
        onlyOwners
        returns (bool b)
    {
        Transaction memory t = addOwnerTransactions[index];

        require(t.executed == false, "Transaction has been executed!");

        addOwnerTransactions[index].executed = true;

        for (uint256 i = 0; i < nonConfirmedAddOwnerTransactions.length; i++) {
            Transaction memory tr = nonConfirmedAddOwnerTransactions[i];
            if (tr.index == index) {
                nonConfirmedAddOwnerTransactions[
                    i
                ] = nonConfirmedAddOwnerTransactions[
                    nonConfirmedAddOwnerTransactions.length - 1
                ];
                nonConfirmedAddOwnerTransactions.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Returns add owner transaction.
     */
    function getAddOwnerTransaction(uint256 index)
        external
        view
        virtual
        returns (Transaction memory transaction)
    {
        return addOwnerTransactions[index];
    }

    /**
     * @dev Returns add owner transaction confirmations.
     */
    function getAddOwnerTransactionConfirmations(uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        return addOwnerConfirmations[index];
    }

    /**
     * @dev Returns Non confirmed add owner transactions.
     */
    function getNonConfirmedAddOwnerTransactions()
        external
        view
        virtual
        returns (Transaction[] memory transaction)
    {
        return nonConfirmedAddOwnerTransactions;
    }

    /**
     * @dev Remove owner from array
     *
     * - `addr` addres to remove.
     */
    function removeOwner(address addr) internal onlyOwners {
        require(addr != address(0), "Address is invalid!");
        require(isOwner[addr] == true, "Owner exists!");
        require(_owners.length > 1, "Could not be less than 1!");

        for (uint256 i = 0; i < _owners.length; i++) {
            address a = _owners[i];
            if (addr == a) {
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();
                break;
            }
        }

        isOwner[addr] = false;
    }

    /**
     * @dev Create remove owner transaction
     *
     * - `addr` address to remove.
     * - `description` some information about event.
     */
    function removeOwnerTransaction(address addr, string memory description)
        external
        payable
        onlyOwners
        returns (Transaction memory t)
    {
        require(addr != address(0), "Address is invalid!");
        uint256 index = removeOwnerIndex;
        removeOwnerTransactions[index] = Transaction(
            false,
            addr,
            index,
            description,
            block.timestamp
        );
        removeOwnerConfirmations[index].push(msg.sender);
        nonConfirmedRemoveOwnerTransactions.push(
            removeOwnerTransactions[index]
        );
        removeOwnerIndex++;
        return removeOwnerTransactions[index];
    }

    /**
     * @dev Confirm remove owner transaction
     *
     * - `index` index of transaction.
     */
    function removeOwnerConfirmTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            removeOwnerConfirmations[index].length > 0,
            "Transaction not exists"
        );
        bool exists = false;
        address[] memory addrs = removeOwnerConfirmations[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == msg.sender) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        removeOwnerConfirmations[index].push(msg.sender);
        removeOwnerTransactions[index].time = block.timestamp;
        return true;
    }

    /**
     * @dev Execute remove owner transaction
     *
     * - `index` index of transaction.
     */
    function removeOwnerExecute(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            removeOwnerConfirmations[index].length >= owners().length,
            "Transaction not confirmed!"
        );

        removeOwnerRemoveExecute(index);
        removeOwner(removeOwnerTransactions[index].value);

        return true;
    }

    /**
     * @dev Remove „remove owner transaction„
     *
     * - `index` index of transaction.
     */
    function removeOwnerRemove(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            removeOwnerConfirmations[index].length >= 0,
            "Transaction not confirmed!"
        );

        return removeOwnerRemoveExecute(index);
    }

    /**
     * @dev Remove „remove owner“
     *
     * - `index` index of transaction.
     */
    function removeOwnerRemoveExecute(uint256 index)
        internal
        onlyOwners
        returns (bool b)
    {
        Transaction memory t = removeOwnerTransactions[index];

        require(t.executed == false, "Transaction has been executed!");

        removeOwnerTransactions[index].executed = true;

        for (
            uint256 i = 0;
            i < nonConfirmedRemoveOwnerTransactions.length;
            i++
        ) {
            Transaction memory tr = nonConfirmedRemoveOwnerTransactions[i];
            if (tr.index == index) {
                nonConfirmedRemoveOwnerTransactions[
                    i
                ] = nonConfirmedRemoveOwnerTransactions[
                    nonConfirmedRemoveOwnerTransactions.length - 1
                ];
                nonConfirmedRemoveOwnerTransactions.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Returns remove owner transaction.
     */
    function getRemoveOwnerTransaction(uint256 index)
        external
        view
        virtual
        returns (Transaction memory transaction)
    {
        return removeOwnerTransactions[index];
    }

    /**
     * @dev Returns remove owner transaction confirmations.
     */
    function getRemoveOwnerTransactionConfirmations(uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        return removeOwnerConfirmations[index];
    }

    /**
     * @dev Returns Non confirmed remove owner transactions.
     */
    function getNonConfirmedRemoveOwnerTransactions()
        external
        view
        virtual
        returns (Transaction[] memory transaction)
    {
        return nonConfirmedRemoveOwnerTransactions;
    }
}
