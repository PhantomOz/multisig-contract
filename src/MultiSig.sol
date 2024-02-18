// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error OWNERSLIST_CANT_BE_EMPTY();
error NO_CONFIRMATION_MUST_BE_IN_RANGE_WITH_LIST();
error ADDRESS_CANT_BE_ZEROADDRESS();
error ADDRESSES_ON_LIST_NOT_UNIQUE();
error NOT_OWNER();
error INDEX_OUT_OF_BOUNDS();
error ALREADY_EXECUTED();
error ALREADY_CONFIRMED();
error ALREADY_REVOKED();
error TRANSACTION_FAILED();

contract MultiSigWallet {
    address[] private owners;
    mapping(address => bool) private addressIsOwner;
    uint256 public numOfConfirmationRequired;
    Transaction[] private transactions;
    mapping(uint256 => mapping(address => bool)) private transactionIsConfirmed;

    event Deposit(address _from, uint256 _value);

    struct Transaction {
        address to;
        bytes data;
        uint256 value;
        bool isExecuted;
        uint256 numOfConfirmation;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    constructor(address[] memory _owners, uint256 _numOfConfirmationRequired) {
        if (_owners.length == 0) {
            revert OWNERSLIST_CANT_BE_EMPTY();
        }
        if (
            _numOfConfirmationRequired == 0 ||
            _numOfConfirmationRequired > _owners.length
        ) {
            revert NO_CONFIRMATION_MUST_BE_IN_RANGE_WITH_LIST();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) {
                revert ADDRESS_CANT_BE_ZEROADDRESS();
            }
            if (addressIsOwner[owner]) {
                revert ADDRESSES_ON_LIST_NOT_UNIQUE();
            }

            addressIsOwner[owner] = true;
            owners = _owners;
        }

        numOfConfirmationRequired = _numOfConfirmationRequired;
    }

    //Private functions as modifiers
    function onlyOwnerAndTxExists(uint256 _index) private view {
        if (!addressIsOwner[msg.sender]) {
            revert NOT_OWNER();
        }
        if (_index >= transactions.length) {
            revert INDEX_OUT_OF_BOUNDS();
        }
    }
    function notExecuted(uint256 _index) private view {
        if (transactions[_index].isExecuted) {
            revert ALREADY_EXECUTED();
        }
    }

    //createTransaction
    function createTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external {
        transactions.push(Transaction(_to, _data, _value, false, 0));
    }
    //confirmTransaction
    function confirmTransaction(uint256 _index) external {
        onlyOwnerAndTxExists(_index);
        notExecuted(_index);
        if (transactionIsConfirmed[_index][msg.sender]) {
            revert ALREADY_CONFIRMED();
        }

        Transaction memory _transaction = transactions[_index];
        transactionIsConfirmed[_index][msg.sender] = true;
        _transaction.numOfConfirmation += 1;
    }
    //executeTransaction
    function executeTransaction(uint256 _index) external returns (bool) {
        onlyOwnerAndTxExists(_index);
        notExecuted(_index);

        Transaction memory _transaction = transactions[_index];
        _transaction.isExecuted = true;
        (bool s, ) = payable(_transaction.to).call{value: _transaction.value}(
            _transaction.data
        );
        if (!s) {
            revert TRANSACTION_FAILED();
        }
        return s;
    }
    //RevokeTransaction
    function revokeConfirmation(uint256 _index) external {
        onlyOwnerAndTxExists(_index);
        notExecuted(_index);

        if (!transactionIsConfirmed[_index][msg.sender]) {
            revert ALREADY_REVOKED();
        }
        Transaction memory _transaction = transactions[_index];
        transactionIsConfirmed[_index][msg.sender] = false;
        _transaction.numOfConfirmation -= 1;
    }

    //view functions
    function getTransactions()
        external
        view
        returns (Transaction[] memory _trx)
    {
        _trx = transactions;
    }

    function getOwners() external view returns (address[] memory _owners) {
        _owners = owners;
    }

    function getTransaction(
        uint256 _index
    ) external view returns (Transaction memory _tx) {
        if (_index >= transactions.length) {
            revert INDEX_OUT_OF_BOUNDS();
        }
        _tx = transactions[_index];
    }
}
