// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <=0.8.7;

import "./IERC20.sol";
import "./Context.sol";
import "./Owners.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * to implement supply mechanisms].
 *
 * We have followed general guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, Owners {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;

    string private _name;
    string private _symbol;

    address private _burnWallet;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     *
     * All these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns wallet where will receive ethers.
     */
    function burnWallet() external view virtual returns (address) {
        return _burnWallet;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        uint256 amount,
        uint8 decimals_,
        address burnWallet_
    ) internal virtual {
        require(_msgSender() != address(0), "ERC20: mint to the zero address");
        require(amount > 0, "Amount should be greater than 0");
        _beforeTokenTransfer(address(0), _msgSender(), amount);

        _totalSupply += amount;
        _balances[_msgSender()] += amount;
        _decimals = decimals_;
        _burnWallet = burnWallet_;

        emit Transfer(address(0), _msgSender(), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Increase totalsupply by adding {amount} - will be received to {receiver}
     *
     * - `amount` mmount to increase.
     */
    function increaseSupply(uint256 amount) internal onlyOwners {
        require(amount > 0, "Amount should be greater than 0");

        _totalSupply += amount;
        _balances[receiver()] += amount;

        emit Transfer(address(0), receiver(), amount);
    }

    /**
     * @dev Decrease totalsupply by removing {amount} from burn wallet
     *
     * - `amount` mmount to decrease.
     */
    function decreaseSupply(uint256 amount) internal onlyOwners {
        require(amount > 0, "Amount should be greater than 0");
        require(
            _balances[_burnWallet] >= amount,
            "ERC20: burn amount exceeds balance"
        );

        _balances[_burnWallet] -= amount;
        _totalSupply -= amount;

        emit Transfer(_burnWallet, address(0), amount);
    }

    /**
     * @dev Create increase supply transaction
     *
     * - `amount` mmount to increase.
     * - `description` some information about event.
     */
    function increaseSupplyTransaction(
        uint256 amount,
        string memory description
    ) external payable onlyOwners returns (TransactionIncreaseSupply memory t) {
        require(amount > 0, "Amount should be greater than 0");
        uint256 index = increaseSupplyIndex;
        increaseSupplyTransactions[index] = TransactionIncreaseSupply(
            false,
            amount,
            index,
            description,
            block.timestamp
        );
        increaseSupplyConfirmations[index].push(_msgSender());
        nonConfirmedIncreaseSupplyTransactions.push(
            increaseSupplyTransactions[index]
        );
        increaseSupplyIndex++;
        return increaseSupplyTransactions[index];
    }

    /**
     * @dev Confirm increase supply transaction by index
     *
     * - `index` index of transaction.
     */
    function increaseSupplyConfirmTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            increaseSupplyConfirmations[index].length > 0,
            "Transaction not exists"
        );
        bool exists = false;
        address[] memory addrs = increaseSupplyConfirmations[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == _msgSender()) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        increaseSupplyConfirmations[index].push(_msgSender());
        increaseSupplyTransactions[index].time = block.timestamp;
        return true;
    }

    /**
     * @dev Execute increase supply transaction by index
     *
     * - `index` index of transaction.
     */
    function increaseSupplyExecute(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            increaseSupplyConfirmations[index].length >= owners().length,
            "Transaction not confirmed!"
        );

        increaseSupplyRemoveTransactionExecute(index);
        increaseSupply(increaseSupplyTransactions[index].increase);
        return true;
    }

    /**
     * @dev Delete increase supply transaction by index
     *
     * - `index` index of transaction.
     */
    function increaseSupplyRemoveTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            increaseSupplyConfirmations[index].length >= 0,
            "Transaction not confirmed!"
        );

        return increaseSupplyRemoveTransactionExecute(index);
    }

    /**
     * @dev Delete increase supply transaction by index
     *
     * - `index` index of transaction.
     */
    function increaseSupplyRemoveTransactionExecute(uint256 index)
        internal
        onlyOwners
        returns (bool b)
    {
        TransactionIncreaseSupply memory t = increaseSupplyTransactions[index];

        require(t.executed == false, "Transaction has been executed!");

        increaseSupplyTransactions[index].executed = true;

        for (
            uint256 i = 0;
            i < nonConfirmedIncreaseSupplyTransactions.length;
            i++
        ) {
            TransactionIncreaseSupply
                memory tr = nonConfirmedIncreaseSupplyTransactions[i];
            if (tr.index == index) {
                nonConfirmedIncreaseSupplyTransactions[
                    i
                ] = nonConfirmedIncreaseSupplyTransactions[
                    nonConfirmedIncreaseSupplyTransactions.length - 1
                ];
                nonConfirmedIncreaseSupplyTransactions.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Create decrease supply transaction
     *
     * - `amount` amount to decrease.
     * - `description` some information about event.
     */
    function decreaseSupplyTransaction(
        uint256 amount,
        string memory description
    ) external payable onlyOwners returns (TransactionDecreaseSupply memory t) {
        require(amount > 0, "Amount should be greater than 0");
        uint256 index = decreaseSupplyIndex;
        decreaseSupplyTransactions[index] = TransactionDecreaseSupply(
            false,
            amount,
            index,
            description,
            block.timestamp
        );
        decreaseSupplyConfirmations[index].push(_msgSender());
        nonConfirmedDecreaseSupplyTransactions.push(
            decreaseSupplyTransactions[index]
        );
        decreaseSupplyIndex++;
        return decreaseSupplyTransactions[index];
    }

    /**
     * @dev Confirm decrease supply transaction by index
     *
     * - `index` index of transaction.
     */
    function decreaseSupplyConfirmTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            decreaseSupplyConfirmations[index].length > 0,
            "Transaction not exists"
        );
        bool exists = false;
        address[] memory addrs = decreaseSupplyConfirmations[index];
        for (uint256 i = 0; i < addrs.length; i++) {
            address addr = addrs[i];

            if (addr == _msgSender()) {
                exists = true;
                break;
            }
        }
        require(exists == false, "The owner has confirmed the transaction");
        decreaseSupplyConfirmations[index].push(_msgSender());
        decreaseSupplyTransactions[index].time = block.timestamp;
        return true;
    }

    /**
     * @dev Execute decrease supply transaction by index
     *
     * - `index` index of transaction.
     */
    function decreaseSupplyExecute(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            decreaseSupplyConfirmations[index].length >= owners().length,
            "Transaction not confirmed!"
        );

        decreaseSupplyRemoveTransactionExecute(index);
        decreaseSupply(decreaseSupplyTransactions[index].decrease);
        return true;
    }

    /**
     * @dev Delete decrease supply transaction by index
     *
     * - `index` index of transaction.
     */
    function decreaseSupplyRemoveTransaction(uint256 index)
        external
        payable
        onlyOwners
        returns (bool b)
    {
        require(
            decreaseSupplyConfirmations[index].length >= 0,
            "Transaction not confirmed!"
        );

        return decreaseSupplyRemoveTransactionExecute(index);
    }

    /**
     * @dev Delete decrease supply transaction by index
     *
     * - `index` index of transaction.
     */
    function decreaseSupplyRemoveTransactionExecute(uint256 index)
        internal
        onlyOwners
        returns (bool b)
    {
        TransactionDecreaseSupply memory t = decreaseSupplyTransactions[index];

        require(t.executed == false, "Transaction has been executed!");

        decreaseSupplyTransactions[index].executed = true;

        for (
            uint256 i = 0;
            i < nonConfirmedDecreaseSupplyTransactions.length;
            i++
        ) {
            TransactionDecreaseSupply
                memory tr = nonConfirmedDecreaseSupplyTransactions[i];
            if (tr.index == index) {
                nonConfirmedDecreaseSupplyTransactions[
                    i
                ] = nonConfirmedDecreaseSupplyTransactions[
                    nonConfirmedDecreaseSupplyTransactions.length - 1
                ];
                nonConfirmedDecreaseSupplyTransactions.pop();
                break;
            }
        }

        return true;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}
