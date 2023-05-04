// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {LoanManager} from "./LoanManager.sol";
import {IERC20} from "./IERC20.sol";

contract Vault is ReentrancyGuard {
    mapping(address => uint) public userDeposits;
    uint public totalDeposits;
    mapping(address => uint) public userScores;
    mapping(address => uint) public userSessions;
    mapping(address => bool) public userWithdrawals;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    LoanManager public loanManager;

    constructor() {
        owner = msg.sender;
    }

    function setLoanManager(address _loanManager) public onlyOwner {
        loanManager = LoanManager(_loanManager);
    }

    function deposit() public payable nonReentrant {
        _deposit(msg.sender, msg.value);
    }

    function withdraw() public nonReentrant {
        require(userDeposits[msg.sender] > 0, "The user didn't deposit any funds.");
        require(loanManager.totalLoans(msg.sender) == 0, "Cannot withdraw with active loans.");

        userWithdrawals[msg.sender] = true;

        (bool success, ) = payable(msg.sender).call{
            value: userDeposits[msg.sender]
        }("");

        require(success, "Unsuccessful withdrawal.");

        totalDeposits -= userDeposits[msg.sender];
        userDeposits[msg.sender] = 0;
    }

    function _deposit(address user, uint amt) internal {
        require(amt > 0, "Only non-zero deposits allowed.");
        userDeposits[user] += amt;
        totalDeposits += amt;

        // If the user withdrew the funds, a new session starts and the score is set to 0
        if (userWithdrawals[user]) {
            userWithdrawals[user] = false;
            userScores[user] = 0;
            userSessions[user] += 1;
        }

        // The score represents the number of deposits of a user
        userScores[user] += 1;
    }

    function getUserLoanLimit(address user) public view returns (uint) {
        // User can get loan of up to 50% of their deposits
        return userDeposits[user];
    }

    // Function that computes the score of a user for a given session
    function getUserScore(address _user) public view returns(uint) {
        return (totalDeposits * userScores[_user]) / 100;
    }
}
