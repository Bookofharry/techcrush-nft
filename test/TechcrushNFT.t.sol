// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {TechcrushNFT} from "../src/TechcrushNFT.sol";

contract NFTReceiver is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

contract NonReceiver {}

contract TechcrushNFTTest is Test {
    TechcrushNFT internal nft;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    string internal constant METADATA_URI = "ipfs://test-metadata/1.json";

    function setUp() public {
        nft = new TechcrushNFT();
    }

    function testCollectionIdentityAndInitialOwner() public view {
        assertEq(nft.name(), "Techcrush");
        assertEq(nft.symbol(), "TCRUSH");
        assertEq(nft.owner(), address(this));
        assertEq(nft.totalMinted(), 0);
    }

    function testMintAssignsOwnershipAndExactMetadataURI() public {
        uint256 tokenId = nft.mint(alice, METADATA_URI);
        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.totalMinted(), 1);
        assertEq(nft.tokenURI(tokenId), METADATA_URI);
    }

    function testOnlyOwnerCanMint() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        nft.mint(alice, METADATA_URI);
        assertEq(nft.totalMinted(), 0);
    }

    function testMultipleMintsKeepSeparateMetadata() public {
        nft.mint(alice, METADATA_URI);
        uint256 secondId = nft.mint(bob, "ipfs://test-metadata/2.json");
        assertEq(secondId, 2);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.tokenURI(1), METADATA_URI);
        assertEq(nft.tokenURI(2), "ipfs://test-metadata/2.json");
    }

    function testEmptyMetadataRevertsWithoutConsumingTokenId() public {
        vm.expectRevert(TechcrushNFT.EmptyMetadataURI.selector);
        nft.mint(alice, "");
        assertEq(nft.totalMinted(), 0);
        assertEq(nft.mint(alice, METADATA_URI), 1);
    }

    function testZeroRecipientRevertsWithoutConsumingTokenId() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        nft.mint(address(0), METADATA_URI);
        assertEq(nft.totalMinted(), 0);
        assertEq(nft.mint(alice, METADATA_URI), 1);
    }

    function testSafeMintToReceiverContract() public {
        NFTReceiver receiver = new NFTReceiver();
        nft.mint(address(receiver), METADATA_URI);
        assertEq(nft.ownerOf(1), address(receiver));
    }

    function testUnsafeReceiverRevertsEntireMint() public {
        NonReceiver receiver = new NonReceiver();
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(receiver)));
        nft.mint(address(receiver), METADATA_URI);
        assertEq(nft.totalMinted(), 0);
        assertEq(nft.mint(alice, METADATA_URI), 1);
    }

    function testTokenOwnerCanTransferWithoutBeingContractOwner() public {
        nft.mint(alice, METADATA_URI);
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.tokenURI(1), METADATA_URI);
        assertEq(nft.owner(), address(this));
    }

    function testUnapprovedAccountCannotTransfer() public {
        nft.mint(alice, METADATA_URI);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, bob, 1));
        nft.transferFrom(alice, bob, 1);
        assertEq(nft.ownerOf(1), alice);
    }

    function testNonexistentTokenHasNoURI() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        nft.tokenURI(1);
    }

    function testNewContractOwnerControlsMinting() public {
        nft.transferOwnership(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        nft.mint(bob, METADATA_URI);
        vm.prank(alice);
        nft.mint(bob, METADATA_URI);
        assertEq(nft.ownerOf(1), bob);
    }
}
