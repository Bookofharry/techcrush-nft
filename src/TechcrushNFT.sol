// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Techcrush NFT
/// @notice A student ERC-721 collection. Only the contract owner can mint.
contract TechcrushNFT is ERC721URIStorage, Ownable {
    uint256 public totalMinted;

    error EmptyMetadataURI();

    constructor() ERC721("Techcrush", "TCRUSH") Ownable(msg.sender) {}

    /// @param recipient Wallet or ERC-721 receiver that will own the new NFT.
    /// @param metadataURI Complete metadata URL, e.g. ipfs://<CID>/1.json.
    /// @return tokenId The new token's identifier, starting at 1.
    function mint(address recipient, string memory metadataURI) external onlyOwner returns (uint256 tokenId) {
        if (bytes(metadataURI).length == 0) revert EmptyMetadataURI();

        tokenId = ++totalMinted;
        _safeMint(recipient, tokenId);
        // Store the complete URL without appending another token ID.
        _setTokenURI(tokenId, metadataURI);
    }
}
