// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Vault} from "./Vault.sol";
import {IERC20} from "./IERC20.sol";
import {ReentrancyGuard} from "./ReentrancyGuard.sol";

contract LoanManager is ReentrancyGuard {
    Vault internal vault;

    address internal loanToken;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    mapping(address => uint) public totalLoans;

    mapping(address => mapping(uint => bool)) redeemsPerSession;

    constructor(address _vault) {
        vault = Vault(_vault);
        owner = msg.sender;
    }

    function setLoanToken(address _loanToken) public {
        loanToken = _loanToken;
    }

    function takeLoan() public nonReentrant {
        _takeLoan(msg.sender);
    }

    function returnLoan() public nonReentrant {
        IERC20(loanToken).transferFrom(
            msg.sender,
            address(this),
            totalLoans[msg.sender]
        );
        totalLoans[msg.sender] = 0;
    }

    function _takeLoan(address user) internal {
        uint loanAmt = vault.getUserLoanLimit(user) - totalLoans[user];
        require(
            loanAmt > 0,
            "can only loan if difference of loans and deposits > 0!"
        );
        totalLoans[user] += loanAmt;
        IERC20(loanToken).transfer(user, loanAmt);
    }
}
