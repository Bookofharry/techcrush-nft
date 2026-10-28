// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {TechcrushNFT} from "../src/TechcrushNFT.sol";

contract DeployTechcrushNFT is Script {
    function run() external returns (TechcrushNFT nft) {
        require(block.chainid == 11155111 || block.chainid == 31337, "Use Sepolia or local Anvil");

        vm.startBroadcast();
        nft = new TechcrushNFT();
        vm.stopBroadcast();

        console2.log("Techcrush NFT deployed at:", address(nft));
        console2.log("Contract owner:", nft.owner());
        console2.log("Chain ID:", block.chainid);
    }
}
