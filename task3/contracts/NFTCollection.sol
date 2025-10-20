// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title NFTCollection
 * @dev ERC721 NFT contract with minting functionality
 */
contract NFTCollection is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Base URI for token metadata
    string private _baseTokenURI;

    // Maximum supply of NFTs
    uint256 public maxSupply;

    // Minting price
    uint256 public mintPrice;

    // Events
    event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI);
    event MintPriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newMaxSupply);

    /**
     * @dev Constructor
     * @param _name Token name
     * @param _symbol Token symbol
     * @param _maxSupply Maximum supply of NFTs
     * @param _mintPrice Price to mint an NFT
     * @param _initialBaseURI Base URI for token metadata
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintPrice,
        string memory _initialBaseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        _baseTokenURI = _initialBaseURI;
    }

    /**
     * @dev Mint a new NFT
     * @param to Address to mint the NFT to
     * @param tokenURI URI for the token metadata
     */
    function mintNFT(address to, string memory tokenURI) public payable returns (uint256) {
        require(totalSupply() < maxSupply, "NFTCollection: Max supply reached");
        require(msg.value >= mintPrice, "NFTCollection: Insufficient payment");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(to, tokenId, tokenURI);

        return tokenId;
    }

    /**
     * @dev Batch mint NFTs
     * @param to Address to mint NFTs to
     * @param tokenURIs Array of token URIs
     */
    function batchMintNFT(address to, string[] memory tokenURIs) public payable returns (uint256[] memory) {
        require(tokenURIs.length > 0, "NFTCollection: Empty token URIs");
        require(totalSupply() + tokenURIs.length <= maxSupply, "NFTCollection: Exceeds max supply");
        require(msg.value >= mintPrice * tokenURIs.length, "NFTCollection: Insufficient payment");

        uint256[] memory tokenIds = new uint256[](tokenURIs.length);

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = mintNFT(to, tokenURIs[i]);
            tokenIds[i] = tokenId;
        }

        return tokenIds;
    }

    /**
     * @dev Set mint price (only owner)
     * @param _mintPrice New mint price
     */
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceUpdated(_mintPrice);
    }

    /**
     * @dev Set max supply (only owner)
     * @param _maxSupply New max supply
     */
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply >= totalSupply(), "NFTCollection: New max supply too low");
        maxSupply = _maxSupply;
        emit MaxSupplyUpdated(_maxSupply);
    }

    /**
     * @dev Set base URI (only owner)
     * @param _newBaseURI New base URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    /**
     * @dev Withdraw contract balance (only owner)
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NFTCollection: No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "NFTCollection: Withdraw failed");
    }

    /**
     * @dev Get total number of minted NFTs
     */
    function totalSupply() public view override(ERC721Enumerable) returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Override base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Override required functions
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Override required functions
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Override required functions
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override supportsInterface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}