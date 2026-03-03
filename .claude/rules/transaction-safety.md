---
paths:
  - "rust/src/transaction/**"
  - "rust/src/api/transaction_api.rs"
  - "lib/src/features/transfer/**"
description: Transaction construction and signing safety rules
---

# Transaction Safety Rules

## Signing

- ALL signing happens in Rust - only signed raw tx bytes cross FFI
- Private keys NEVER leave Rust layer
- Every transaction must include correct `chainId` (EIP-155 replay protection)

## Gas Estimation

- EIP-1559 chains: use `eth_feeHistory`, provide slow/standard/fast tiers
- Legacy chains: use `eth_gasPrice`, allow manual adjustment
- Always `eth_estimateGas` + 10-20% buffer to prevent out-of-gas
- Gas insufficient: explicit user-facing error, never silent failure

## UI Confirmation (Flutter side)

- Before signing, display: target address (full, EIP-55), amount, gas fee, chain info
- Address display: NEVER truncate on confirmation screen (anti address-poisoning)
- First-time address: show warning prompt
- Large amount transfers: force password re-confirmation (threshold configurable)

## Network Safety

- All RPC: HTTPS only
- Timeout: 10s per request, max 3 retries with exponential backoff
- Custom RPC: warn user about non-HTTPS risks
- Never include sensitive data in URL parameters
