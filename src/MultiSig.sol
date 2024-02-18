// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error OWNERSLIST_CANT_BE_EMPTY();
error NO_CONFIRMATION_MUST_BE_IN_RANGE_WITH_LIST();
error ADDRESS_CANT_BE_ZEROADDRESS();
error ADDRESSES_ON_LIST_NOT_UNIQUE();

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public addressIsOwner;
    uint256 public numOfConfirmationRequired;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) private transactionIsConfirmed;

    struct Transaction {
        address to;
        bytes data;
        uint256 value;
        bool isExecuted;
        uint256 numOfConfirmation;
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
            revert();
        }
        if (_index >= transactions.length) {
            revert();
        }
    }
    function notExecuted(uint256 _index) private view {
        if (transactions[_index].isExecuted) {
            revert();
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
            revert();
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
            revert();
        }
        return s;
    }
    //RevokeTransaction
    function revokeConfirmation(uint256 _index) external {
        onlyOwnerAndTxExists(_index);
        notExecuted(_index);

        if (!transactionIsConfirmed[_index][msg.sender]) {
            revert();
        }
        Transaction memory _transaction = transactions[_index];
        transactionIsConfirmed[_index][msg.sender] = false;
        _transaction.numOfConfirmation -= 1;
    }
}
