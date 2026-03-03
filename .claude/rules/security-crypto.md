---
paths:
  - "rust/src/crypto/**"
  - "rust/src/api/crypto_api.rs"
description: Security rules for cryptography modules
---

# Cryptography Security Rules

## Mandatory Checks Before Any Change

- Verify ALL randomness sources are `OsRng` - grep for `thread_rng`, `rand::random`, `StdRng`
- Verify all sensitive types implement `Zeroize + ZeroizeOnDrop`
- Verify no sensitive data in error messages or Debug/Display output
- Verify `Secret<T>` wrapping on types that shouldn't be printable

## AES-256-GCM Constraints

- One random nonce per encryption (never reuse, never counter-based)
- Format: `nonce(12) || ciphertext || tag(16)` - no deviation
- Decryption must validate tag before returning plaintext

## Argon2id Constraints

- Safety floor: >=32MB memory, >=2 iterations - code must enforce this with compile-time or runtime checks
- Salt: 16 bytes from OsRng, unique per wallet, stored separately
- Calibrated params must be persisted alongside salt

## BIP Standard Compliance

- BIP-39: validate against official test vectors
- BIP-44: path `m/44'/60'/0'/0/{index}` for Ethereum
- EIP-55: checksum encoding for all address display

## Testing Requirements for Crypto Changes

- Round-trip tests (encrypt -> decrypt -> compare) for every code path
- Known test vector validation (BIP-39, BIP-44, EIP-155)
- proptest for invariant verification (any input survives roundtrip)
- Verify zeroize works: test that drop clears memory
- Verify wrong-password/wrong-key returns error, not garbage
