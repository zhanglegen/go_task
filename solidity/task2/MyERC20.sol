// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // 使用0.8.0以上版本，内置溢出检查

contract MyERC20 {
    // 代币基本信息
    string public name;       // 代币名称（如"MyToken"）
    string public symbol;     // 代币符号（如"MTK"）
    uint8 public decimals = 18; // 小数位（ERC20默认18位）
    uint256 public totalSupply; // 总供应量

    // 存储账户余额：address => 余额
    mapping(address => uint256) public balanceOf;

    // 存储授权信息：owner => spender => 授权额度
    mapping(address => mapping(address => uint256)) public allowance;

    // 合约所有者（用于控制mint权限）
    address public owner;

    // 转账事件（标准ERC20要求）
    event Transfer(address indexed from, address indexed to, uint256 value);

    // 授权事件（标准ERC20要求）
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // 构造函数：初始化代币信息和所有者
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender; // 部署者成为初始所有者
    }

    //  modifier：限制仅所有者可调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 标准转账功能：从调用者账户转账给to
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Transfer to zero address"); // 禁止转账到零地址
        require(balanceOf[msg.sender] >= amount, "Insufficient balance"); // 检查余额

        balanceOf[msg.sender] -= amount; // 减少发送者余额
        balanceOf[to] += amount;         // 增加接收者余额
        emit Transfer(msg.sender, to, amount); // 触发转账事件
        return true;
    }

    // 授权功能：允许spender从调用者账户代扣amount额度
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address"); // 禁止授权给零地址

        allowance[msg.sender][spender] = amount; // 记录授权额度
        emit Approval(msg.sender, spender, amount); // 触发授权事件
        return true;
    }

    // 代扣转账：从from账户转账给to（需先授权）
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        // 检查授权额度（调用者是否被允许从from转账amount）
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");

        balanceOf[from] -= amount;              // 减少from余额
        balanceOf[to] += amount;                // 增加to余额
        allowance[from][msg.sender] -= amount;  // 减少授权额度
        emit Transfer(from, to, amount);        // 触发转账事件
        return true;
    }

    // 增发代币：仅所有者可调用，增加totalSupply并转账给to
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Mint to zero address");

        totalSupply += amount;       // 增加总供应量
        balanceOf[to] += amount;     // 增加接收者余额
        emit Transfer(address(0), to, amount); // 从零地址转账（增发标准）
    }
}