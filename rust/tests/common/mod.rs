#![allow(dead_code)]
/// Shared test fixtures for integration tests.
use unvault_core::crypto::argon2::Argon2Params;

/// BIP-39 test vector #1: all-zero entropy → "abandon ... about" (12 words).
pub const TEST_MNEMONIC_12: &[u8] =
    b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

/// BIP-39 test vector: 24-word all-zero entropy → "abandon ... art" (24 words).
pub const TEST_MNEMONIC_24: &[u8] =
    b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art";

/// BIP-39 test vector seed: "abandon...about" + passphrase "TREZOR".
pub fn test_seed_trezor() -> Vec<u8> {
    hex::decode(
        "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531\
         f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
    )
    .unwrap()
}

/// Fast Argon2id parameters at the safety floor (for testing only).
pub fn fast_argon2_params() -> Argon2Params {
    Argon2Params { memory_kib: 32 * 1024, iterations: 2, parallelism: 1 }
}

/// A deterministic 16-byte salt for testing.
pub fn test_salt() -> [u8; 16] {
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
}
