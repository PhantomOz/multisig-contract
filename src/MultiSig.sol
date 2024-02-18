// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    mapping(uint256 => mapping(address => Transaction))
        private idToAdressTransaction;
    address[] public owners;
    mapping(address => bool) public addressIsOwner;
    uint256 public numOfConfirmationRequired;

    struct Transaction {
        address to;
        bytes data;
        uint256 value;
        bool isExecuted;
        uint256 numOfConfirmation;
    }

    constructor(address[] memory _owner, uint256 _numOfConfirmationRequired) {}
}
