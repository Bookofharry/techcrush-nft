param(
    [string]$Password = ''
)
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Techcrush - Sepolia NFT minting'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$castPath = Join-Path $env:USERPROFILE '.foundry\bin\cast.exe'
$rpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com'
$account = Get-Content -LiteralPath 'evidence/public-account.json' -Raw | ConvertFrom-Json
$deployment = Get-Content -LiteralPath 'evidence/sepolia-deployment.json' -Raw | ConvertFrom-Json
$hosting = Get-Content -LiteralPath 'metadata/hosting.json' -Raw | ConvertFrom-Json
$contractAddress = $deployment.contractAddress
$metadataUri = $hosting.metadataUri
$pendingPath = 'evidence/sepolia-mint-pending.json'

function Invoke-SepoliaRpc([string]$Method, [object[]]$RpcParams) {
    $request = @{ jsonrpc = '2.0'; id = 1; method = $Method; params = $RpcParams } | ConvertTo-Json -Depth 12
    $response = Invoke-RestMethod -Uri $rpcUrl -Method Post -ContentType 'application/json' -Body $request -TimeoutSec 45
    if ($response.error) { throw "RPC $Method failed: $($response.error.message)" }
    return $response.result
}

$chainId = & $castPath chain-id --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$chainId".Trim() -ne '11155111') { throw 'Sepolia RPC check failed.' }
$contractOwner = & $castPath call $contractAddress 'owner()(address)' --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$contractOwner".Trim() -ne $account.address) { throw 'Signing account is not the contract owner.' }

if (Test-Path -LiteralPath $pendingPath) {
    $pending = Get-Content -LiteralPath $pendingPath -Raw | ConvertFrom-Json
    if ($pending.contractAddress -ne $contractAddress -or $pending.metadataUri -ne $metadataUri) { throw 'Existing mint record does not match this configuration.' }
    $transactionHash = $pending.transactionHash
    Write-Host 'Checking the existing mint transaction without sending another.'
} else {
    $minted = & $castPath call $contractAddress 'totalMinted()(uint256)' --rpc-url $rpcUrl
    if ($LASTEXITCODE -ne 0 -or "$minted".Trim() -ne '0') { throw 'This collection already has a mint. Return to chat to inspect it before sending another.' }

    $metadata = Invoke-RestMethod -Uri $metadataUri -TimeoutSec 45
    if ($metadata -is [string]) { $metadata = $metadata.Trim().Trim([char]65279) | ConvertFrom-Json }
    if ($metadata.name -ne 'Techcrush #1' -or $metadata.image -ne $hosting.imageUri) { throw 'Hosted metadata does not match the prepared artwork.' }
    $imageCheck = Invoke-WebRequest -Uri $metadata.image -Method Head -UseBasicParsing -TimeoutSec 45
    if ($imageCheck.StatusCode -ne 200) { throw 'The NFT artwork is not accessible.' }

    $calldata = & $castPath calldata 'mint(address,string)' $account.address $metadataUri
    if ($LASTEXITCODE -ne 0) { throw 'Could not encode the mint request.' }
    $estimateHex = Invoke-SepoliaRpc 'eth_estimateGas' @(@{ from = $account.address; to = $contractAddress; data = "$calldata".Trim(); value = '0x0' })
    $estimatedGas = [Convert]::ToInt64($estimateHex, 16)
    $gasLimit = [long][Math]::Ceiling($estimatedGas * 1.2)
    if ($gasLimit -gt 16000000) { throw 'Unexpected minting gas estimate; return to chat to inspect it.' }

    Write-Host 'Mint Techcrush #1 on Ethereum Sepolia.' -ForegroundColor Cyan
    Write-Host "Contract: $contractAddress"
    Write-Host "Recipient: $($account.address)"
    Write-Host "Metadata: $metadataUri"
    Write-Host "Node gas estimate: $estimatedGas; limit with margin: $gasLimit"
    $passArgs = @()
    if ($Password) {
        $passArgs = @('--password', $Password)
    } else {
        Write-Host 'Enter your wallet password at the hidden local prompt.'
    }
    $sendOutput = & $castPath send $contractAddress 'mint(address,string)' $account.address $metadataUri --rpc-url $rpcUrl --account $account.accountAlias --from $account.address --gas-limit $gasLimit --async @passArgs
    if ($LASTEXITCODE -ne 0) { throw 'Mint submission did not complete. Return to chat before retrying.' }
    $transactionHash = "$sendOutput".Trim()
    if ($transactionHash -notmatch '^0x[0-9a-fA-F]{64}$') { throw 'Unexpected transaction output; return to chat before retrying.' }
    [ordered]@{ transactionHash = $transactionHash; contractAddress = $contractAddress; metadataUri = $metadataUri } | ConvertTo-Json | Set-Content -LiteralPath $pendingPath -Encoding UTF8
}

Write-Host "Waiting for mint transaction: $transactionHash"
$receipt = $null
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    $receipt = Invoke-SepoliaRpc 'eth_getTransactionReceipt' @($transactionHash)
    if ($receipt) { break }
    Start-Sleep -Seconds 3
}
if (-not $receipt) { throw 'Transaction is still pending. Its hash is saved; return to chat without minting again.' }
if ($receipt.status -ne '0x1') { throw 'Mint transaction failed. Its hash is saved; return to chat before retrying.' }

$tokenOwner = & $castPath call $contractAddress 'ownerOf(uint256)(address)' 1 --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$tokenOwner".Trim() -ne $account.address) { throw 'Token owner verification failed.' }
$onchainUri = & $castPath call $contractAddress 'tokenURI(uint256)(string)' 1 --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$onchainUri".Trim().Trim('"') -ne $metadataUri) { throw 'Token metadata verification failed.' }

[ordered]@{
    network = 'Ethereum Sepolia'
    chainId = 11155111
    contractAddress = $contractAddress
    transactionHash = $transactionHash
    tokenId = 1
    owner = $account.address
    metadataUri = $metadataUri
    imageUri = $hosting.imageUri
    receiptStatus = $receipt.status
    blockNumber = $receipt.blockNumber
    explorerUrl = "https://sepolia.etherscan.io/tx/$transactionHash"
} | ConvertTo-Json | Set-Content -LiteralPath 'evidence/sepolia-mint.json' -Encoding UTF8

Write-Host ''
Write-Host 'NFT MINTING VERIFIED SUCCESSFUL' -ForegroundColor Green
Write-Host 'Network: Ethereum Sepolia (11155111)'
Write-Host 'NFT: Techcrush #1 / Token ID: 1'
Write-Host "Contract: $contractAddress"
Write-Host "Owner: $($account.address)"
Write-Host "Transaction: $transactionHash"
Write-Host 'Metadata URI verified against the prepared metadata.'
Write-Host "Explorer: https://sepolia.etherscan.io/tx/$transactionHash"
Write-Host 'Take your minting screenshot of this window, then return to chat.' -ForegroundColor Cyan
