// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BeggingContract {
    // 记录合约所有者（部署者）
    address private immutable _owner;
    
    // 记录每个地址的捐赠总额（address => 捐赠金额，单位：wei）
    mapping(address => uint256) private _donations;

    // 仅所有者可调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    // 构造函数：初始化所有者为部署合约的地址
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev 捐赠函数：允许用户向合约发送以太币，自动记录捐赠金额
     * 可通过调用该函数转账，或直接向合约地址转账（会触发receive函数）
     */
    function donate() public payable {
        require(msg.value > 0, "Donation amount must be greater than 0");
        _donations[msg.sender] += msg.value; // 累加捐赠金额
    }

    /**
     * @dev 接收直接转账的以太币（当用户不调用donate，直接向合约地址转账时触发）
     */
    receive() external payable {
        donate(); // 复用donate的逻辑，确保直接转账也被记录
    }

    /**
     * @dev 提款函数：仅所有者可提取合约中所有资金
     */
    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        require(totalBalance > 0, "No funds to withdraw");
        
        // 将合约余额转账给所有者（transfer会自动处理失败回滚）
        payable(_owner).transfer(totalBalance);
    }

    /**
     * @dev 查询指定地址的捐赠总额
     * @param donor 要查询的捐赠者地址
     * @return 捐赠总额（单位：wei）
     */
    function getDonation(address donor) external view returns (uint256) {
        return _donations[donor];
    }

    /**
     * @dev 查看合约当前总余额（可选辅助函数）
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}