// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Land_NFT is ERC721URIStorage, Ownable {

    event LandNFTMinted(uint256 indexed landId, address indexed owner);
    event LandNFTTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event CrossChainTransferInitiated(uint256 indexed tokenId, address indexed from, string destinationChain);
    event CrossChainTransferCompleted(uint256 indexed tokenId, address indexed to);

    constructor() ERC721("LandToken", "LTKN") Ownable(msg.sender) {}

    function mintNFT(address to, uint256 tokenId, string memory tokenURI) external onlyOwner {
        require(bytes(tokenURI).length > 0, "Token URI must be set before minting");
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        emit LandNFTMinted(tokenId, to);
    }

    function transferNFT(address from, address to, uint256 tokenId) external onlyOwner {
        _transfer(from, to, tokenId);
        emit LandNFTTransferred(from, to, tokenId);
    }

    function initiateCrossChainTransfer(address from, uint256 tokenId, string memory destinationChain) external onlyOwner {
        _transfer(from, address(this), tokenId);
        emit CrossChainTransferInitiated(tokenId, from, destinationChain);
    }

    function completeCrossChainTransfer(uint256 tokenId, address to) external onlyOwner {
        _transfer(address(this), to, tokenId);
        emit CrossChainTransferCompleted(tokenId, to);
    }
}
