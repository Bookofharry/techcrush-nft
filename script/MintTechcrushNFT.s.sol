// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {TechcrushNFT} from "../src/TechcrushNFT.sol";

contract MintTechcrushNFT is Script {
    function run() external returns (uint256 tokenId) {
        require(block.chainid == 11155111 || block.chainid == 31337, "Use Sepolia or local Anvil");
        address nftAddress = vm.envAddress("NFT_CONTRACT_ADDRESS");
        address recipient = vm.envAddress("NFT_RECIPIENT");
        string memory metadataURI = vm.envString("NFT_METADATA_URI");
        require(nftAddress.code.length > 0, "No contract at NFT_CONTRACT_ADDRESS");
        TechcrushNFT nft = TechcrushNFT(nftAddress);

        vm.startBroadcast();
        tokenId = nft.mint(recipient, metadataURI);
        vm.stopBroadcast();

        console2.log("Minted token ID:", tokenId);
        console2.log("NFT owner:", nft.ownerOf(tokenId));
        console2.log("Metadata URI:", nft.tokenURI(tokenId));
    }
}
