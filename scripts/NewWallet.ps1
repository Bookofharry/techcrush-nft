param([string]$AccountName = 'techcrush-deployer')

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'Techcrush - Create encrypted wallet'

if ($AccountName -notmatch '^[a-zA-Z0-9_-]+$') {
    throw 'Use letters, numbers, underscores, or hyphens for the account name.'
}

$castPath = Join-Path $env:USERPROFILE '.foundry\bin\cast.exe'
if (-not (Test-Path -LiteralPath $castPath)) {
    $castPath = (Get-Command cast -ErrorAction Stop).Source
}

$keystoreDirectory = Join-Path $env:USERPROFILE '.foundry\keystores'
$keystorePath = Join-Path $keystoreDirectory $AccountName
if (Test-Path -LiteralPath $keystorePath) {
    throw "Account '$AccountName' already exists. No existing wallet was changed."
}

New-Item -ItemType Directory -Path $keystoreDirectory -Force | Out-Null
# Ensure Cast asks locally instead of using a password inherited from the shell.
Remove-Item Env:CAST_PASSWORD -ErrorAction SilentlyContinue

Write-Host 'Create your new Techcrush assignment wallet.' -ForegroundColor Cyan
Write-Host 'Choose a password at the hidden prompt below. Typing will not be visible.'
Write-Host 'Keep the password: you will need it to deploy and mint.'
Write-Host 'Do not enter the password or private key in chat.'
Write-Host ''

# Passing an existing directory and account name saves an encrypted keystore.
# Never call `cast wallet new` without a destination: that prints the private key.
& $castPath wallet new $keystoreDirectory $AccountName | Tee-Object -Variable creationOutput
if ($LASTEXITCODE -ne 0) {
    throw "Wallet creation did not finish successfully (exit code $LASTEXITCODE)."
}

$walletData = Get-Content -LiteralPath $keystorePath -Raw | ConvertFrom-Json
$publicAddress = [string]$walletData.address
if ([string]::IsNullOrWhiteSpace($publicAddress)) {
    # Some Cast versions omit the public address from their keystore JSON.
    # With an encrypted destination, wallet-new output contains the public
    # address and file path, not the private key. The password prompt stays local.
    $addressMatch = [regex]::Match(($creationOutput -join "`n"), '(?i)Address:\s*(0x[0-9a-f]{40})\b')
    if ($addressMatch.Success) { $publicAddress = $addressMatch.Groups[1].Value }
}
if ($publicAddress -notmatch '^0x') { $publicAddress = '0x' + $publicAddress }
if ($publicAddress -notmatch '^0x[0-9a-fA-F]{40}$') {
    throw 'Keystore created, but its public address could not be read. Do not recreate or overwrite it.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$evidenceDirectory = Join-Path $projectRoot 'evidence'
New-Item -ItemType Directory -Path $evidenceDirectory -Force | Out-Null
$publicRecord = Join-Path $evidenceDirectory 'public-account.json'
[ordered]@{
    accountAlias = $AccountName
    address = $publicAddress
    intendedNetwork = 'Ethereum Sepolia'
    chainId = 11155111
} | ConvertTo-Json | Set-Content -LiteralPath $publicRecord -Encoding UTF8

Write-Host ''
Write-Host 'Wallet created successfully.' -ForegroundColor Green
Write-Host "Public address: $publicAddress"
Write-Host "Encrypted keystore: $keystorePath"
Write-Host 'The public address has been saved to the project. You can return to chat.'
