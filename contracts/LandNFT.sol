// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LandNFT is ERC721URIStorage, Ownable {

    event LandNFTMinted(uint256 indexed landId, address indexed owner);
    event LandNFTtransferred(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() ERC721("LandToken", "LTKN") Ownable(msg.sender) {}

    function mintNFT(address to, uint256 landId, string memory tokenURI) external onlyOwner {
        require(bytes(tokenURI).length > 0, "Token URI must be set before minting");
        _mint(to, landId);
        _setTokenURI(landId, tokenURI);
        emit LandNFTMinted(landId, to);
    }

    function transferNFT(address from, address to, uint256 tokenId) external onlyOwner {
        _transfer(from, to, tokenId);
        emit LandNFTtransferred(from, to, tokenId);
    }
}
