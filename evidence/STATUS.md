# Project status

Verified on 27 October 2026 using Foundry 1.8.5 and Solidity 0.8.30.

- Compilation succeeded: `compilation.txt`.
- All 12 contract tests passed: `testing.txt`.
- Formatting check passed.
- Deployment and minting scripts were broadcast successfully to local Anvil
  (chain ID 31337), using disposable Anvil accounts and a test-only metadata URI.
- Separate RPC reads confirmed token 1's owner and its exact stored URI.
- Local script runs emitted Foundry source-tracing and missing-Etherscan-config
  warnings, but execution succeeded and the RPC assertions passed.
- Original AI-generated artwork saved in `../assets/techcrush.png`; generation
  prompt saved in `../assets/ARTWORK.md`.

- An encrypted `techcrush-deployer` keystore now exists outside the repository.
  The user supplied its public address, saved in `public-account.json`:
  `0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292`.
- The address had a zero Sepolia ETH balance when checked on 27 October 2026.
- On 28 October 2026, its balance was confirmed as 0.05 Sepolia ETH.
- A Sepolia deployment simulation succeeded with an estimated requirement of
  approximately 0.0016 test ETH. The interactive deployment window has been
  opened. That initial gas estimate proved too low for the live network.
- The initial Sepolia deployment transaction failed with receipt status `0x0`
  and consumed its full 1,593,507 gas allowance. Transaction hash:
  `0x556d1f94cfb915ec06699d709945d534a8d1b21bd349ac382eb23f1deb893698`.
- The Sepolia node estimates 8,444,167 gas for the same deployment bytecode. A
  direct `eth_call` simulation with a higher allowance succeeded. The Windows
  helper now uses `eth_estimateGas` plus 20% and `forge create` for deployment.
  The corrected deployment succeeded on 28 October 2026, with receipt status
  `0x1`. Contract owner was independently verified through the Sepolia RPC.
- Deployed contract: `0x62DEd3949ED5EF6af1784Cace3393e504B9656D9`.
- Successful transaction:
  `0xf4b789bcd502abd2bc6793480e7cdb77bc5819d0938502485dd74e1f7eabe22d`.
- Token #1 minted successfully on 28 October 2026:
  - Transaction: `0xac5697902f1ff96f482a2388dc1f39f4adc864ab012ce42703ea46278877eb80`
  - Token ID: `1`
  - Owner: `0xc5e058e6B8BeAC6EFa667e958D8cA0E3EE36a292`
  - Verified on-chain via `ownerOf(1)` and `tokenURI(1)`.
  - Receipt status: `0x1` (Success).

Still pending: taking screenshots of the outputs, assembling the Google Doc, and LMS submission.
