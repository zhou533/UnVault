---
paths:
  - "rust/src/**/tests/**"
  - "rust/src/**/tests.rs"
  - "rust/tests/**"
  - "rust/benches/**"
description: Rust testing standards
---

# Rust Testing Standards

## Unit Tests (inline `#[cfg(test)]`)

- Place in same file as implementation
- Test both success paths and error paths
- For crypto: always test with known test vectors from standards

## Integration Tests (`rust/tests/`)

- Cross-module flow tests only (single-module logic belongs in unit tests)
- Key flows to cover:
  - `crypto_integration`: password -> Argon2id -> AES-GCM encrypt -> decrypt -> verify
  - `wallet_integration`: mnemonic -> create wallet -> derive accounts -> verify addresses
  - `transaction_integration`: build tx -> sign -> verify signature -> encode

## Property Tests (proptest)

- Encrypt/decrypt roundtrip: any `Vec<u8>` input survives
- Key derivation determinism: same password + salt -> same key
- Mnemonic roundtrip: generate -> to_entropy -> from_entropy -> matches

## Benchmarks (criterion)

- `argon2_bench`: measure latency across parameter combinations
- `signing_bench`: transaction signing throughput
- Run with `cargo bench`

## Coverage

| Module | Target |
|--------|--------|
| `crypto/` | >= 90% |
| `wallet/` | >= 85% |
| `transaction/` | >= 85% |
| `api/` | >= 70% |
| **Overall** | **>= 80%** |

Tool: `cargo tarpaulin --out xml`
