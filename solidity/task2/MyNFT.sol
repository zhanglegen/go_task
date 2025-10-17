// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入OpenZeppelin的ERC721标准实现和计数器工具
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // 新增：元数据扩展合约
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721URIStorage  {
    // 使用Counters管理tokenId（确保唯一性）
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // 构造函数：初始化NFT名称和符号
    constructor(
        string memory _name,  // NFT名称（如"MyFirstNFT"）
        string memory _symbol // NFT符号（如"MFN"）
    ) ERC721(_name, _symbol) {}

    // 铸造NFT函数：向recipient地址铸造一个新NFT，并关联元数据
    function mintNFT(address recipient, string memory tokenURI) public returns (uint256) {
        // 获取当前tokenId（从1开始计数）
        uint256 newTokenId = _tokenIdCounter.current() + 1;
        _tokenIdCounter.increment(); // 计数器递增

        // 安全铸造NFT（包含接收者是否支持ERC721的检查）
        _safeMint(recipient, newTokenId);
        // 设置该NFT的元数据链接（IPFS地址）
        _setTokenURI(newTokenId, tokenURI);

        return newTokenId; // 返回铸造的tokenId
    }

    // 重写tokenURI函数（OpenZeppelin v4.9+需要显式重写）
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }
}