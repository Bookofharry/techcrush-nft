# Techcrush NFT

A student ERC-721 project for the Techcrush NFT assignment, inspired by
[the instructor's example](https://github.com/Bravolakmedia/bravolak2nft).
Collection name: **Techcrush**. Symbol: **TCRUSH**. Target network: **Sepolia**.
This is a student project, not an official Techcrush collectible.

## Sepolia deployment

- Contract: [0x62DEd3949ED5EF6af1784Cace3393e504B9656D9](https://sepolia.etherscan.io/address/0x62DEd3949ED5EF6af1784Cace3393e504B9656D9)
- Successful deployment: [transaction receipt](https://sepolia.etherscan.io/tx/0xf4b789bcd502abd2bc6793480e7cdb77bc5819d0938502485dd74e1f7eabe22d)
- Network: Ethereum Sepolia, chain ID 11155111.
- Minting status is recorded in `evidence/sepolia-mint.json` once complete.

## What the contract does

`src/TechcrushNFT.sol` uses OpenZeppelin ERC721URIStorage and Ownable.
The deploying account owns the contract and can call `mint(recipient, metadataURI)`.
Each successful mint creates a sequential token ID starting at 1. The recipient
owns that token and can transfer it under ERC-721 rules. Being the contract owner
does not give automatic permission to transfer someone else's token.

Each token stores its complete metadata URI. No token ID is appended to the URL,
avoiding the teaching example's `1.json1` issue. Metadata cannot be changed through
this contract after minting, so check the hosted JSON and artwork first. The URI
is fixed, but externally hosted content may still change or become unavailable.

## Setup

Install Foundry and Git. Clone this repository with its pinned submodules:

```sh
git clone --recurse-submodules <YOUR_REPOSITORY_URL>
cd <YOUR_REPOSITORY_DIRECTORY>
```

If already cloned, run `git submodule update --init --recursive`.
The compiler is pinned to Solidity 0.8.30 and OpenZeppelin to v5.4.0.

On this Windows machine, Foundry is in `$HOME\.foundry\bin`. To make commands
available in the current PowerShell session:

```powershell
$env:Path = "$HOME\.foundry\bin;" + $env:Path
```

## Compile and test

```powershell
forge build
forge test -vv
forge fmt --check
```

Tests cover collection identity, mint ownership, exact metadata URLs, sequential
IDs, owner-only minting, empty metadata, invalid recipients, safe receiver
contracts, transfers, nonexistent tokens, and changes of contract owner.
Capture the successful build and test output for your submission. If the build
is cached, `forge build --force` will run the compiler again for the screenshot.

## Artwork and metadata

This project hosts its original artwork and metadata in its public GitHub
repository. Minting uses raw HTTPS URLs pinned to specific Git commits so later
branch edits cannot change the referenced files. GitHub must remain accessible
and the repository public for wallets to retrieve them. `metadata/hosting.json`
records the final URLs once published. IPFS is an alternative, not an ERC-721
requirement.

The artwork is `assets/techcrush.png`. The complete mintable metadata is
`metadata/1.json` once prepared. `metadata/1.template.json` is a separate IPFS
template and must not be minted as-is.

### Optional IPFS hosting

1. Review the generated original image in `assets/techcrush.png`.
2. Upload/pin the artwork to IPFS and obtain its file CID.
3. Copy `metadata/1.template.json` to `metadata/1.json`; replace
   `REPLACE_WITH_ARTWORK_CID` with the actual image CID. If the upload is wrapped
   in a directory, include the image filename in the URL.
4. Upload/pin the completed JSON to IPFS. Its full URL is the minting metadata
   URI: `ipfs://<JSON_FILE_CID>` or `ipfs://<DIRECTORY_CID>/1.json`.
5. Check that the JSON and its image resolve before minting. Do not mint the
   template or use a local filesystem path as the metadata URI.

## Deploy on Sepolia

You need a Sepolia RPC endpoint and a wallet funded with Sepolia test ETH.
For a new account on Windows, run the setup script and enter a password at the
hidden local prompt. It saves an encrypted keystore outside this repository
and records only the public address in `evidence/public-account.json`:

```powershell
.\scripts\NewWallet.ps1
```

Run this once. It refuses to overwrite an existing account. Back up the encrypted
keystore and remember its password; there is no password reset. The address can
receive test ETH from the Google Cloud Sepolia faucet:
https://cloud.google.com/application/web3/faucet/ethereum/sepolia

Alternatively, to use an existing account instead of creating a new one, import
it into Foundry's encrypted keystore using the interactive local prompt:

```powershell
cast wallet import techcrush-deployer --interactive
```

Enter credentials only in the local prompt; never paste keys or recovery phrases
into chat, commit them, or include them in screenshots. The account name above
is a local keystore alias, not a new blockchain address.

Set your actual RPC URL in the current PowerShell session, then deploy:

On this Windows workspace, `scripts/DeploySepolia.ps1` runs the deployment using
the saved public account and a public Sepolia RPC endpoint. It prompts locally
for the keystore password, estimates deployment gas through the Sepolia RPC with
a 20% margin, verifies the receipt and contract owner, records the
result in `evidence/sepolia-deployment.json`, and updates `.env`. It checks for a
previous deployment before sending another transaction. Run it once and take
the deployment screenshot after it reports verified success.

The equivalent manual commands are:

```powershell
$env:SEPOLIA_RPC_URL = '<YOUR_SEPOLIA_RPC_URL>'
forge create src/TechcrushNFT.sol:TechcrushNFT --rpc-url $env:SEPOLIA_RPC_URL --account techcrush-deployer --gas-estimate-multiplier 120 --broadcast
```

The PowerShell helper verifies chain ID 11155111 (Sepolia). The separate Solidity
deployment script remains available for learning and local Anvil checks, but its
local gas estimate underestimated the requirements of the live Sepolia network.
Save the deployed address and transaction hash. A simulation without
`--broadcast` is not an on-chain deployment. Capture the successful Sepolia
broadcast output. Never include an RPC API key in a screenshot.

## Mint and verify

On this Windows workspace, run `scripts/MintSepolia.ps1` after
`metadata/hosting.json` is prepared. It checks the hosted metadata and image,
uses a live Sepolia gas estimate with a 20% margin, prompts for the keystore
password locally, and verifies the resulting receipt, token owner, and URI.
It saves the submitted transaction hash to prevent duplicate retries.

Use the same signing account that deployed the contract:

```powershell
$env:NFT_CONTRACT_ADDRESS = '<YOUR_DEPLOYED_CONTRACT_ADDRESS>'
$env:NFT_RECIPIENT = '<YOUR_WALLET_ADDRESS>'
$env:NFT_METADATA_URI = '<YOUR_COMPLETE_METADATA_URL>'
cast send $env:NFT_CONTRACT_ADDRESS 'mint(address,string)' $env:NFT_RECIPIENT $env:NFT_METADATA_URI --rpc-url $env:SEPOLIA_RPC_URL --account techcrush-deployer --gas-estimate-multiplier 120
cast call $env:NFT_CONTRACT_ADDRESS 'ownerOf(uint256)(address)' 1 --rpc-url $env:SEPOLIA_RPC_URL
cast call $env:NFT_CONTRACT_ADDRESS 'tokenURI(uint256)(string)' 1 --rpc-url $env:SEPOLIA_RPC_URL
```

Save the mint transaction hash and token ID. In your wallet, select Sepolia and,
if it supports importing NFTs, use the contract address and token ID. MetaMask
is one option, not a requirement. Wallet artwork rendering depends
on metadata availability and wallet support; `ownerOf` verifies on-chain ownership.
Capture the successful mint and, if available, the wallet's NFT view.

## Submission

See `evidence/CHECKLIST.md`. Put your GitHub URL and four real screenshots
(compilation, testing, Sepolia deployment, Sepolia minting) in a Google Doc.
Set access to **Anyone with the link / Viewer**, then submit that document URL
to the LMS by **1 November 2026 at 23:00 Africa/Lagos**.

Local compilation and tests do not establish that deployment or minting happened
on Sepolia. Public transaction hashes will be recorded when those steps finish.
