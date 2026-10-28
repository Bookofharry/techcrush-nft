$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Techcrush - Sepolia deployment'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$forgePath = Join-Path $env:USERPROFILE '.foundry\bin\forge.exe'
$castPath = Join-Path $env:USERPROFILE '.foundry\bin\cast.exe'
$rpcUrl = 'https://ethereum-sepolia-rpc.publicnode.com'
$account = Get-Content -LiteralPath 'evidence/public-account.json' -Raw | ConvertFrom-Json
$broadcastPath = 'broadcast/DeployTechcrushNFT.s.sol/11155111/run-latest.json'
$createResultPath = 'evidence/sepolia-create-result.json'

function Invoke-SepoliaRpc([string]$Method, [object[]]$RpcParams) {
    $request = @{ jsonrpc = '2.0'; id = 1; method = $Method; params = $RpcParams } | ConvertTo-Json -Depth 12
    $response = Invoke-RestMethod -Uri $rpcUrl -Method Post -ContentType 'application/json' -Body $request -TimeoutSec 45
    if ($response.error) { throw "RPC $Method failed: $($response.error.message)" }
    return $response.result
}

$chainId = & $castPath chain-id --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$chainId".Trim() -ne '11155111') { throw 'Sepolia RPC check failed.' }

$contractAddress = $null
$transactionHash = $null
if (Test-Path -LiteralPath $createResultPath) {
    $previousCreate = Get-Content -LiteralPath $createResultPath -Raw | ConvertFrom-Json
    $contractAddress = $previousCreate.deployedTo
    $transactionHash = $previousCreate.transactionHash
    if (-not $contractAddress -or -not $transactionHash) { throw 'Existing deployment result needs inspection before retrying.' }
} elseif (Test-Path -LiteralPath $broadcastPath) {
    $previousBroadcast = Get-Content -LiteralPath $broadcastPath -Raw | ConvertFrom-Json
    $previousCreates = @($previousBroadcast.transactions | Where-Object { $_.transactionType -eq 'CREATE' -and $_.contractName -eq 'TechcrushNFT' })
    if ($previousCreates.Count -ne 1 -or -not $previousCreates[0].hash) { throw 'Previous broadcast needs inspection before retrying.' }
    $previousReceipt = Invoke-SepoliaRpc 'eth_getTransactionReceipt' @($previousCreates[0].hash)
    if (-not $previousReceipt) { throw 'Previous transaction has no receipt yet; refusing a duplicate deployment.' }
    if ($previousReceipt.status -eq '0x1') {
        $contractAddress = $previousCreates[0].contractAddress
        $transactionHash = $previousCreates[0].hash
    } elseif ($previousReceipt.status -eq '0x0') {
        $previousReceipt | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath 'evidence/sepolia-failed-deployment-receipt.json' -Encoding UTF8
        Write-Host 'Previous transaction was confirmed failed. Retrying with gas estimated by the Sepolia node.'
    } else {
        throw 'Unrecognised previous transaction status; refusing to redeploy.'
    }
}

if (-not $transactionHash) {
    $artifact = Get-Content -LiteralPath 'out/TechcrushNFT.sol/TechcrushNFT.json' -Raw | ConvertFrom-Json
    $creationCode = [string]$artifact.bytecode.object
    if ($creationCode -notmatch '^0x') { $creationCode = '0x' + $creationCode }
    $estimateHex = Invoke-SepoliaRpc 'eth_estimateGas' @(@{ from = $account.address; data = $creationCode; value = '0x0' })
    $estimatedGas = [Convert]::ToInt64($estimateHex, 16)
    $gasLimit = [long][Math]::Ceiling($estimatedGas * 1.2)
    if ($gasLimit -gt 16000000) { throw 'Unexpected deployment gas estimate; return to chat to inspect it.' }
    [ordered]@{ rpcGasEstimate = $estimatedGas; gasLimit = $gasLimit; chainId = 11155111 } | ConvertTo-Json | Set-Content -LiteralPath 'evidence/sepolia-gas-estimate.json' -Encoding UTF8

    Write-Host 'Deploy Techcrush (TCRUSH) to Ethereum Sepolia.' -ForegroundColor Cyan
    Write-Host "Signing account: $($account.address)"
    Write-Host "Sepolia node gas estimate: $estimatedGas; limit with margin: $gasLimit"
    Write-Host 'Enter your wallet password at the hidden local prompt.'
    Write-Host 'Do not share your password or private key in chat.'
    Write-Host ''
    & $forgePath create src/TechcrushNFT.sol:TechcrushNFT --rpc-url $rpcUrl --account $account.accountAlias --from $account.address --gas-limit $gasLimit --broadcast --json | Tee-Object -Variable creationOutput | Tee-Object -FilePath 'evidence/sepolia-create-output.txt'
    if ($LASTEXITCODE -ne 0) { throw 'Deployment did not complete. Return to chat before retrying.' }
    $createResult = ($creationOutput -join "`n") | ConvertFrom-Json
    if (-not $createResult.deployedTo -or -not $createResult.transactionHash) { throw 'Deployment output needs inspection before retrying.' }
    $createResult | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $createResultPath -Encoding UTF8
    $contractAddress = $createResult.deployedTo
    $transactionHash = $createResult.transactionHash
} else {
    Write-Host 'Existing successful deployment found. Verifying it without deploying again.'
}

$receiptText = & $castPath receipt $transactionHash --rpc-url $rpcUrl --json
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the deployment receipt.' }
$receipt = $receiptText | ConvertFrom-Json
if ($receipt.status -ne '0x1') { throw 'Deployment receipt is not successful.' }
$contractOwner = & $castPath call $contractAddress 'owner()(address)' --rpc-url $rpcUrl
if ($LASTEXITCODE -ne 0 -or "$contractOwner".Trim() -ne $account.address) { throw 'Contract owner verification failed.' }

[ordered]@{
    network = 'Ethereum Sepolia'
    chainId = 11155111
    contractAddress = $contractAddress
    transactionHash = $transactionHash
    owner = $account.address
    receiptStatus = $receipt.status
    blockNumber = $receipt.blockNumber
    explorerUrl = "https://sepolia.etherscan.io/tx/$transactionHash"
} | ConvertTo-Json | Set-Content -LiteralPath 'evidence/sepolia-deployment.json' -Encoding UTF8

$localConfig = Get-Content -LiteralPath '.env'
$localConfig = $localConfig -replace '^NFT_CONTRACT_ADDRESS=.*$', "NFT_CONTRACT_ADDRESS=$contractAddress"
$localConfig | Set-Content -LiteralPath '.env' -Encoding ASCII

Write-Host ''
Write-Host 'DEPLOYMENT VERIFIED SUCCESSFUL' -ForegroundColor Green
Write-Host 'Network: Ethereum Sepolia (11155111)'
Write-Host "Collection: Techcrush (TCRUSH)"
Write-Host "Contract: $contractAddress"
Write-Host "Owner: $($account.address)"
Write-Host "Transaction: $transactionHash"
Write-Host "Explorer: https://sepolia.etherscan.io/tx/$transactionHash"
Write-Host ''
Write-Host 'Take your deployment screenshot of this window, then return to chat.' -ForegroundColor Cyan
