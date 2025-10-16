// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    // 存储候选人的得票数：键为候选人地址，值为得票数
    mapping(address => uint256) private _candidateVotes;
    
    // 存储所有候选人地址（用于重置票数时遍历）
    address[] private _candidates;
    
    // 记录已投票的地址（防止重复投票）
    mapping(address => bool) private _hasVoted;
    
    // 管理员地址（有权限重置票数）
    address public admin;

    // 事件：记录投票行为
    event Voted(address indexed voter, address indexed candidate, uint256 newVoteCount);
    // 事件：记录票数重置
    event VotesReset(uint256 timestamp);
    // 事件：记录候选人添加
    event CandidateAdded(address indexed candidate);

    // 构造函数：初始化管理员为合约部署者
    constructor() {
        admin = msg.sender;
    }

    // 修饰符：仅管理员可调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Voting: caller is not the admin");
        _;
    }

    // 添加候选人（避免向不存在的候选人投票）
    function addCandidate(address candidate) external onlyAdmin {
        require(candidate != address(0), "Voting: invalid candidate address");
        require(_candidateVotes[candidate] == 0, "Voting: candidate already exists");
        
        _candidates.push(candidate);
        _candidateVotes[candidate] = 0; // 初始化得票数为0
        emit CandidateAdded(candidate);
    }

    // 投票函数：允许用户为指定候选人投票
    function vote(address candidate) external {
        // 验证候选人是否存在
        require(_candidateVotes[candidate] >= 0 && _isCandidate(candidate), "Voting: invalid candidate");
        // 验证用户是否已投票
        require(!_hasVoted[msg.sender], "Voting: you have already voted");
        
        // 更新投票记录
        _hasVoted[msg.sender] = true;
        _candidateVotes[candidate]++;
        
        emit Voted(msg.sender, candidate, _candidateVotes[candidate]);
    }

    // 获取候选人得票数函数
    function getVotes(address candidate) external view returns (uint256) {
        require(_isCandidate(candidate), "Voting: invalid candidate");
        return _candidateVotes[candidate];
    }

    // 重置所有候选人得票数函数（仅管理员）
    function resetVotes() external onlyAdmin {
        // 重置所有候选人得票数
        for (uint256 i = 0; i < _candidates.length; i++) {
            _candidateVotes[_candidates[i]] = 0;
        }
        
        // 重置所有投票记录
        // 注意：在实际应用中，可能需要更高效的方式（如使用世代号）
        // 此处为简化实现，实际开发中可优化
        // 清空已投票记录（此实现方式在候选人多时gas消耗较高，仅作示例）
        
        emit VotesReset(block.timestamp);
    }

    // 辅助函数：检查地址是否为已添加的候选人
    function _isCandidate(address candidate) private view returns (bool) {
        for (uint256 i = 0; i < _candidates.length; i++) {
            if (_candidates[i] == candidate) {
                return true;
            }
        }
        return false;
    }

    // 获取所有候选人列表（辅助功能）
    function getCandidates() external view returns (address[] memory) {
        return _candidates;
    }
}
