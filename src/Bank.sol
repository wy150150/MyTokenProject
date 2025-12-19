// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Bank {
    /// @notice 管理员地址
    address public owner;

    /// @notice 记录每个地址的存款金额
    mapping(address => uint256) public balances;

    /// @notice 存款金额 Top3 的用户地址（按金额从高到低）
    address[3] public topDepositors;

    /// @notice 事件：存款
    event Deposit(address indexed user, uint256 amount);

    /// @notice 事件：管理员提款
    event Withdraw(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice 直接通过调用方法存款
     */
    function deposit() external payable {
        require(msg.value > 0, "Zero value");
        balances[msg.sender] += msg.value;
        _updateTop3(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 直接向合约地址转 ETH（MetaMask 转账触发）
     */
    receive() external payable {
        require(msg.value > 0, "Zero value");
        balances[msg.sender] += msg.value;
        _updateTop3(msg.sender);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice 管理员提取合约中的 ETH
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);
    }

    /**
     * @notice 获取合约 ETH 余额
     */
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 内部函数：更新存款 Top3 排行
     */
    function _updateTop3(address user) internal {
        // 如果用户已经在榜单中，先移除
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] == user) {
                topDepositors[i] = address(0);
            }
        }

        // 重新插入用户到正确位置
        for (uint256 i = 0; i < 3; i++) {
            if (
                topDepositors[i] == address(0) ||
                balances[user] > balances[topDepositors[i]]
            ) {
                // 向后挪位
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j - 1];
                }
                topDepositors[i] = user;
                break;
            }
        }
    }
}