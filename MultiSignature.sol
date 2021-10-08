// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.9;

abstract contract MultiSignature {
    enum TransactionTypes {
        increaseSupply,
        decreaseSupply,
        changeReceiver,
        addOwner,
        removeOwner
    }

    struct Transaction {
        TransactionTypes trasactionType;
        bool executed;
        uint256 value;
        address addressValue;
        uint256 index;
        uint256 blockTime;
        uint256 lockTime;
        string description;
    }

    struct BaseTransaction {
        uint256 value;
        address addressValue;
        uint256 lockTime;
        string description;
    }

    // Increase supply variables
    uint256 internal increaseSupplyIndex = 0;
    mapping(uint256 => address[]) public increaseSupplyConfirmations;
    mapping(uint256 => Transaction) public increaseSupplyTransactions;
    Transaction[] public nonConfirmedIncreaseSupplyTransactions;

    // Decrease supply variables
    uint256 internal decreaseSupplyIndex = 0;
    mapping(uint256 => address[]) public decreaseSupplyConfirmations;
    mapping(uint256 => Transaction) public decreaseSupplyTransactions;
    Transaction[] public nonConfirmedDecreaseSupplyTransactions;

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
    address[] public _owners;
    mapping(address => bool) public isOwner;
    address public _receiver;

    address public executor;

    /**
     * @dev Modifier checks sender is owner.
     */
    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    /**
     * @dev Modifier checks sender is executor.
     */
    modifier onlyExecutor() {
        require(msg.sender == executor, "not owner");
        _;
    }

    /**
     * @dev Modifier checks sender is executor or owner.
     */
    modifier onlyExecutorOrOwner() {
        require(
            (msg.sender == executor) || isOwner[msg.sender],
            "not executor"
        );
        _;
    }

    constructor(address _executor) {
        address addr = address(msg.sender);
        _owners = [addr];
        isOwner[addr] = true;
        _receiver = addr;
        executor = _executor;
    }

    function getOwners() external view returns (address[] memory owners) {
        return _owners;
    }

    function decreaseSupply(uint256 amount) internal virtual;

    function increaseSupply(uint256 amount) internal virtual;

    function increaseSupplyType() external pure returns (TransactionTypes) {
        return TransactionTypes.increaseSupply;
    }

    function decreaseSupplyType() external pure returns (TransactionTypes) {
        return TransactionTypes.decreaseSupply;
    }

    function changeReceiverType() external pure returns (TransactionTypes) {
        return TransactionTypes.changeReceiver;
    }

    function addOwnerType() external pure returns (TransactionTypes) {
        return TransactionTypes.addOwner;
    }

    function removeOwnerType() external pure returns (TransactionTypes) {
        return TransactionTypes.removeOwner;
    }

    /**
     * @dev Returns transaction.
     */
    function getTransaction(TransactionTypes trType, uint256 index)
        external
        view
        virtual
        returns (Transaction memory transaction)
    {
        if (trType == TransactionTypes.increaseSupply) {
            return increaseSupplyTransactions[index];
        }

        if (trType == TransactionTypes.decreaseSupply) {
            return decreaseSupplyTransactions[index];
        }

        if (trType == TransactionTypes.changeReceiver) {
            return changeReceiverTransactions[index];
        }

        if (trType == TransactionTypes.addOwner) {
            return addOwnerTransactions[index];
        }

        if (trType == TransactionTypes.removeOwner) {
            return removeOwnerTransactions[index];
        }
    }

    /**
     * @dev Returns transaction confirmations.
     */
    function getTransactionConfirmations(TransactionTypes trType, uint256 index)
        external
        view
        virtual
        returns (address[] memory transaction)
    {
        if (trType == TransactionTypes.increaseSupply) {
            return increaseSupplyConfirmations[index];
        }

        if (trType == TransactionTypes.decreaseSupply) {
            return decreaseSupplyConfirmations[index];
        }

        if (trType == TransactionTypes.changeReceiver) {
            return changeReceiverConfirmations[index];
        }

        if (trType == TransactionTypes.addOwner) {
            return addOwnerConfirmations[index];
        }

        if (trType == TransactionTypes.removeOwner) {
            return removeOwnerConfirmations[index];
        }
    }

    /**
     * @dev Returns non confirmed transactions
     */
    function getNonConfirmedTransactions(TransactionTypes trType)
        external
        view
        virtual
        returns (Transaction[] memory transaction)
    {
        if (trType == TransactionTypes.increaseSupply) {
            return nonConfirmedIncreaseSupplyTransactions;
        }

        if (trType == TransactionTypes.decreaseSupply) {
            return nonConfirmedDecreaseSupplyTransactions;
        }

        if (trType == TransactionTypes.changeReceiver) {
            return nonConfirmedChangeReceiverTransactions;
        }

        if (trType == TransactionTypes.addOwner) {
            return nonConfirmedAddOwnerTransactions;
        }

        if (trType == TransactionTypes.removeOwner) {
            return nonConfirmedRemoveOwnerTransactions;
        }
    }

    /**
     * @dev Change executor
     *
     * - `addr` sets executor
     */
    function changeExecutor(address addr) external payable onlyOwners {
        require(addr != address(0), "Address is invalid!");
        executor = addr;
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
     * @dev Create transaction
     */

    function createTransaction(
        TransactionTypes trType,
        BaseTransaction memory transaction
    ) external payable onlyOwners returns (Transaction memory t) {
        if (trType == TransactionTypes.increaseSupply) {
            require(transaction.value > 0, "Amount should be greater than 0");
            uint256 index = increaseSupplyIndex;
            increaseSupplyIndex++;
            return
                createTransactionExecute(
                    index,
                    increaseSupplyTransactions,
                    increaseSupplyConfirmations,
                    nonConfirmedIncreaseSupplyTransactions,
                    transaction,
                    TransactionTypes.increaseSupply
                );
        }

        if (trType == TransactionTypes.decreaseSupply) {
            require(transaction.value > 0, "Amount should be greater than 0");
            uint256 index = decreaseSupplyIndex;
            decreaseSupplyIndex++;
            return
                createTransactionExecute(
                    index,
                    decreaseSupplyTransactions,
                    decreaseSupplyConfirmations,
                    nonConfirmedDecreaseSupplyTransactions,
                    transaction,
                    TransactionTypes.decreaseSupply
                );
        }

        if (trType == TransactionTypes.changeReceiver) {
            require(
                transaction.addressValue != address(0),
                "Address is invalid!"
            );
            uint256 index = changeReceiverIndex;
            changeReceiverIndex++;
            return
                createTransactionExecute(
                    index,
                    changeReceiverTransactions,
                    changeReceiverConfirmations,
                    nonConfirmedChangeReceiverTransactions,
                    transaction,
                    TransactionTypes.changeReceiver
                );
        }

        if (trType == TransactionTypes.addOwner) {
            require(
                transaction.addressValue != address(0),
                "Address is invalid!"
            );
            uint256 index = addOwnerIndex;
            addOwnerIndex++;
            return
                createTransactionExecute(
                    index,
                    addOwnerTransactions,
                    addOwnerConfirmations,
                    nonConfirmedAddOwnerTransactions,
                    transaction,
                    TransactionTypes.addOwner
                );
        }

        if (trType == TransactionTypes.removeOwner) {
            require(
                transaction.addressValue != address(0),
                "Address is invalid!"
            );
            uint256 index = removeOwnerIndex;
            removeOwnerIndex++;
            return
                createTransactionExecute(
                    index,
                    removeOwnerTransactions,
                    removeOwnerConfirmations,
                    nonConfirmedRemoveOwnerTransactions,
                    transaction,
                    TransactionTypes.removeOwner
                );
        }
    }

    /**
     * @dev Create transaction execute
     *
     */
    function createTransactionExecute(
        uint256 index,
        mapping(uint256 => Transaction) storage map,
        mapping(uint256 => address[]) storage confirmation,
        Transaction[] storage nonConfirmed,
        BaseTransaction memory transaction,
        TransactionTypes trType
    ) internal onlyOwners returns (Transaction storage t) {
        map[index] = Transaction({
            trasactionType: trType,
            executed: false,
            value: transaction.value,
            addressValue: transaction.addressValue,
            index: index,
            blockTime: block.timestamp,
            lockTime: transaction.lockTime,
            description: transaction.description
        });
        confirmation[index].push(msg.sender);
        nonConfirmed.push(map[index]);
        return map[index];
    }

    /**
     * @dev Confirm transaction
     *
     * - `trType` type of transaction.
     * - `index` index of transaction.
     */
    function confirmTransaction(TransactionTypes trType, uint256 index)
        external
        payable
        onlyOwners
        returns (bool boolean)
    {
        if (trType == TransactionTypes.increaseSupply) {
            require(
                increaseSupplyConfirmations[index].length > 0,
                "Transaction not exists"
            );
            confirmTransactionExecute(
                index,
                increaseSupplyTransactions,
                increaseSupplyConfirmations,
                nonConfirmedIncreaseSupplyTransactions
            );
        }

        if (trType == TransactionTypes.decreaseSupply) {
            require(
                decreaseSupplyConfirmations[index].length > 0,
                "Transaction not exists"
            );
            return
                confirmTransactionExecute(
                    index,
                    decreaseSupplyTransactions,
                    decreaseSupplyConfirmations,
                    nonConfirmedDecreaseSupplyTransactions
                );
        }

        if (trType == TransactionTypes.changeReceiver) {
            require(
                changeReceiverConfirmations[index].length > 0,
                "Transaction not exists"
            );
            return
                confirmTransactionExecute(
                    index,
                    changeReceiverTransactions,
                    changeReceiverConfirmations,
                    nonConfirmedChangeReceiverTransactions
                );
        }

        if (trType == TransactionTypes.addOwner) {
            require(
                addOwnerConfirmations[index].length > 0,
                "Transaction not exists"
            );
            return
                confirmTransactionExecute(
                    index,
                    addOwnerTransactions,
                    addOwnerConfirmations,
                    nonConfirmedAddOwnerTransactions
                );
        }

        if (trType == TransactionTypes.removeOwner) {
            require(
                removeOwnerConfirmations[index].length > 0,
                "Transaction not exists"
            );
            return
                confirmTransactionExecute(
                    index,
                    removeOwnerTransactions,
                    removeOwnerConfirmations,
                    nonConfirmedRemoveOwnerTransactions
                );
        }

        return false;
    }

    /**
     * @dev Create transaction execute
     */
    function confirmTransactionExecute(
        uint256 index,
        mapping(uint256 => Transaction) storage map,
        mapping(uint256 => address[]) storage confirmation,
        Transaction[] memory nonConfirmed
    ) internal onlyOwners returns (bool boolean) {
        bool exists = false;
        address[] memory addrs = confirmation[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == msg.sender) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        confirmation[index].push(msg.sender);
        map[index].blockTime = block.timestamp;

        for (uint256 i = 0; i < nonConfirmed.length; i++) {
            if (nonConfirmed[i].index == index) {
                nonConfirmed[i] = map[index];
                break;
            }
        }

        return true;
    }

    /**
     * @dev Remove transaction
     */
    function removeTransaction(TransactionTypes trType, uint256 index)
        external
        payable
        onlyOwners
        returns (bool boolean)
    {
        if (trType == TransactionTypes.increaseSupply) {
            checkRemove(index, increaseSupplyConfirmations);
            return
                removeTransactionExecute(
                    index,
                    increaseSupplyTransactions,
                    nonConfirmedIncreaseSupplyTransactions
                );
        }

        if (trType == TransactionTypes.decreaseSupply) {
            checkRemove(index, decreaseSupplyConfirmations);
            return
                removeTransactionExecute(
                    index,
                    decreaseSupplyTransactions,
                    nonConfirmedDecreaseSupplyTransactions
                );
        }

        if (trType == TransactionTypes.changeReceiver) {
            checkRemove(index, changeReceiverConfirmations);
            return
                removeTransactionExecute(
                    index,
                    changeReceiverTransactions,
                    nonConfirmedChangeReceiverTransactions
                );
        }

        if (trType == TransactionTypes.addOwner) {
            checkRemove(index, addOwnerConfirmations);
            return
                removeTransactionExecute(
                    index,
                    addOwnerTransactions,
                    nonConfirmedAddOwnerTransactions
                );
        }

        if (trType == TransactionTypes.removeOwner) {
            checkRemove(index, removeOwnerConfirmations);
            return
                removeTransactionExecute(
                    index,
                    removeOwnerTransactions,
                    nonConfirmedRemoveOwnerTransactions
                );
        }
    }

    /**
     * @dev Remove transaction execute
     *
     */
    function removeTransactionExecute(
        uint256 index,
        mapping(uint256 => Transaction) storage map,
        Transaction[] storage nonConfirmed
    ) internal onlyExecutorOrOwner returns (bool boolean) {
        Transaction memory t = map[index];

        require(t.executed == false, "Transaction has been executed!");

        map[index].executed = true;

        for (uint256 i = 0; i < nonConfirmed.length; i++) {
            Transaction memory tr = nonConfirmed[i];
            if (tr.index == index) {
                nonConfirmed[i] = nonConfirmed[nonConfirmed.length - 1];
                nonConfirmed.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Executte transaction
     */
    function executeTransaction(TransactionTypes trType, uint256 index)
        external
        payable
        onlyExecutorOrOwner
        returns (bool boolean)
    {
        if (trType == TransactionTypes.increaseSupply) {
            checkExecution(
                index,
                increaseSupplyTransactions,
                increaseSupplyConfirmations
            );
            removeTransactionExecute(
                index,
                increaseSupplyTransactions,
                nonConfirmedIncreaseSupplyTransactions
            );
            increaseSupply(increaseSupplyTransactions[index].value);
            return true;
        }

        if (trType == TransactionTypes.decreaseSupply) {
            checkExecution(
                index,
                decreaseSupplyTransactions,
                decreaseSupplyConfirmations
            );
            removeTransactionExecute(
                index,
                decreaseSupplyTransactions,
                nonConfirmedDecreaseSupplyTransactions
            );
            decreaseSupply(decreaseSupplyTransactions[index].value);
        }

        if (trType == TransactionTypes.changeReceiver) {
            checkExecution(
                index,
                changeReceiverTransactions,
                changeReceiverConfirmations
            );
            removeTransactionExecute(
                index,
                changeReceiverTransactions,
                nonConfirmedChangeReceiverTransactions
            );
            changeReceiver(changeReceiverTransactions[index].addressValue);
        }

        if (trType == TransactionTypes.addOwner) {
            checkExecution(index, addOwnerTransactions, addOwnerConfirmations);
            removeTransactionExecute(
                index,
                addOwnerTransactions,
                nonConfirmedAddOwnerTransactions
            );
            addOwner(addOwnerTransactions[index].addressValue);
            return true;
        }

        if (trType == TransactionTypes.removeOwner) {
            checkExecution(
                index,
                removeOwnerTransactions,
                removeOwnerConfirmations
            );
            removeTransactionExecute(
                index,
                removeOwnerTransactions,
                nonConfirmedRemoveOwnerTransactions
            );
            removeOwner(removeOwnerTransactions[index].addressValue);
            return true;
        }
    }

    /**
     * @dev Check transaction execution
     *
     */
    function checkExecution(
        uint256 index,
        mapping(uint256 => Transaction) storage map,
        mapping(uint256 => address[]) storage confirmation
    ) internal view onlyExecutorOrOwner returns (bool boolean) {
        Transaction memory t = map[index];
        uint256 time = t.blockTime + t.lockTime;
        require(time <= block.timestamp, "Time execution failed!");
        uint256 confirmations = confirmation[index].length;
        uint256 ownersLength = _owners.length;

        if (confirmations > ownersLength) {
            return true;
        }

        uint256 nonConfirmations = ownersLength - confirmations;

        require(confirmations > nonConfirmations, "Not enough confirumations");

        return true;
    }

    /**
     * @dev Check remove transaction
     *
     */
    function checkRemove(
        uint256 index,
        mapping(uint256 => address[]) storage confirmation
    ) internal view onlyOwners returns (bool boolean) {
        uint256 confirmations = confirmation[index].length;
        uint256 ownersLength = _owners.length;

        require(confirmations < ownersLength, "Too much confirumations");

        uint256 nonConfirmations = ownersLength - confirmations;

        require(confirmations < nonConfirmations, "Too much confirumations");

        return true;
    }
}
