// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public addressIsOwner;
    uint256 public numOfConfirmationRequired;
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
            revert();
        }
        if (
            _numOfConfirmationRequired == 0 ||
            _numOfConfirmationRequired > _owners.length
        ) {
            revert();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            if (owner == address(0)) {
                revert();
            }
            if (addressIsOwner[owner]) {
                revert();
            }

            addressIsOwner[owner] = true;
            owners = _owners;
        }

        numOfConfirmationRequired = _numOfConfirmationRequired;
    }
}
