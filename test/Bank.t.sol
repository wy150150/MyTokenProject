// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public owner;
    address public user1;
    address public user2;
    address public user3;
    address public user4;

    receive() external payable {}

    function setUp() public {
        owner = address(this);
        bank = new Bank();
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        user4 = address(0x4);

        // 给测试用户一些 ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
    }

    // 1. 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确
    function testDepositBalance() public {
        uint256 depositAmount = 1 ether;
        
        vm.startPrank(user1);
        uint256 balanceBefore = bank.balances(user1);
        bank.deposit{value: depositAmount}();
        uint256 balanceAfter = bank.balances(user1);
        vm.stopPrank();

        assertEq(balanceAfter, balanceBefore + depositAmount, "Balance update mismatch");
    }

    // 2. 检查存款金额的前 3 名用户是否正确
    function testTop3Depositors() public {
        // 情况 A: 1个用户
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        assertEq(bank.topDepositors(0), user1);
        assertEq(bank.topDepositors(1), address(0));
        assertEq(bank.topDepositors(2), address(0));

        // 情况 B: 2个用户
        vm.prank(user2);
        bank.deposit{value: 2 ether}();
        assertEq(bank.topDepositors(0), user2);
        assertEq(bank.topDepositors(1), user1);

        // 情况 C: 3个用户
        vm.prank(user3);
        bank.deposit{value: 3 ether}();
        assertEq(bank.topDepositors(0), user3);
        assertEq(bank.topDepositors(1), user2);
        assertEq(bank.topDepositors(2), user1);

        // 情况 D: 4个用户（淘汰此时最少的 user1）
        vm.prank(user4);
        bank.deposit{value: 4 ether}();
        assertEq(bank.topDepositors(0), user4);
        assertEq(bank.topDepositors(1), user3);
        assertEq(bank.topDepositors(2), user2);

        // 情况 E: 同一个用户多次存款切换排名
        // 目前：user4(4), user3(3), user2(2)
        // 让 user2 再存 3 ether，总额 5 ether，应该升至第1
        vm.prank(user2);
        bank.deposit{value: 3 ether}();
        assertEq(bank.topDepositors(0), user2);
        assertEq(bank.topDepositors(1), user4);
        assertEq(bank.topDepositors(2), user3);
    }

    // 3. 检查只有管理员可取款，其他人不可以取款
    function testWithdrawPermission() public {
        // 先存入一些钱
        vm.prank(user1);
        bank.deposit{value: 5 ether}();

        // 尝试非管理员取款：应该报错
        vm.prank(user1);
        vm.expectRevert("Not owner");
        bank.withdraw(1 ether);

        // 管理员取款：应该成功
        uint256 ownerBalanceBefore = owner.balance;
        bank.withdraw(1 ether);
        assertEq(owner.balance, ownerBalanceBefore + 1 ether);
    }
}
