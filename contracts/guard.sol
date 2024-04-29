// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract ReentrancyGuard {
    uint256 private constant not_entered = 1;
    uint256 private constant entered = 2;
    uint256 private status;

    constructor() {
        status = not_entered;
    }
    modifier noReentrant() {
        noReentrantBefore();
        _;
        noReentrantAfter();
    }

    function noReentrantBefore() private {
        require(status != entered, "ReentrancyGuard: reentrant call");
        status = entered;
    }

    function noReentrantAfter() private {
        status = not_entered;
    }
}