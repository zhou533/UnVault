# Rust Core Rules

## Code Quality

- `cargo clippy -- -D warnings` zero warnings
- `cargo fmt` enforced
- No `unwrap()`/`expect()` in library code - use `thiserror` custom errors
- Minimize `pub` - prefer `pub(crate)` where possible
- No uncommented `unsafe` - each block must document safety invariants
- New crate dependencies require `cargo audit` check

## Memory Safety

- `Zeroize + ZeroizeOnDrop` + `Secret<T>` wrapping (see `security-crypto.md` for checks)
- Use `libc::mlock` for sensitive memory; degrade gracefully if it fails (log warning, don't block)
- Error paths and panic paths must still execute zeroize
- Release builds: strip symbols, disable debug info, enable LTO

## Cryptography

AES-256-GCM and BIP standard constraints: see `security-crypto.md`.

- **Argon2id** parameters:
  - Target: 64MB memory, 3 iterations, parallelism 2-4, 32-byte output
  - Safety floor: >=32MB memory, >=2 iterations (NEVER below this)
  - Dynamic calibration on first wallet creation (target 1-2s latency)
  - Persist calibrated params with salt
- **Salt**: 16 bytes random per wallet, stored separately from ciphertext, never reused

## Error Handling

- `thiserror` for all error types in `error.rs`
- Map to FFI error codes at `api/` boundary (see `ffi-boundary.md`)
- Propagate with `?` operator, provide context at API boundary

## Module Responsibilities

- `api/`: Thin FRB wrappers - ONLY param conversion + error mapping, no business logic
- `crypto/`: Mnemonic (BIP-39), key derivation (BIP-44), Argon2id, AES-GCM, memory safety
- `wallet/`: Wallet struct, account management, BIP-44 path derivation
- `transaction/`: Builder (EIP-1559/Legacy), signer (alloy), gas estimation
- `models/`: Shared types - address (EIP-55), network config

## Testing

See `testing-rust.md` for full standards, coverage targets, and structure.

- Run: `cargo test --all-features --all-targets`
- Coverage: `cargo tarpaulin`
