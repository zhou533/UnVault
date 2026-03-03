//! FFI API for wallet lifecycle operations.
//!
//! Thin wrappers over wallet domain module. Handles parameter conversion
//! and error mapping for the FFI boundary.

use secrecy::ExposeSecret;

use crate::error::{Result, UnvaultError};
use crate::wallet::manager;

/// Creates a new wallet.
///
/// `password`: password as bytes (≥8 chars enforced at Dart layer).
/// `word_count`: 12 or 24.
///
/// Returns: (encrypted_mnemonic, salt, argon2_memory, argon2_iterations, argon2_parallelism,
///           first_address, mnemonic_bytes)
///
/// SECURITY: `mnemonic_bytes` is returned for backup display. Dart must zeroize after use.
pub fn create_wallet(
    password: Vec<u8>,
    word_count: u8,
) -> Result<WalletCreationResponse> {
    let wc = match word_count {
        12 => crate::crypto::mnemonic::WordCount::Words12,
        24 => crate::crypto::mnemonic::WordCount::Words24,
        _ => {
            return Err(UnvaultError::WalletOperation("word_count must be 12 or 24".into()));
        }
    };

    let (result, mnemonic) = manager::create_wallet(&password, wc)?;

    Ok(WalletCreationResponse {
        encrypted_mnemonic: result.encrypted_mnemonic,
        salt: result.salt.to_vec(),
        argon2_memory_kib: result.argon2_params.memory_kib,
        argon2_iterations: result.argon2_params.iterations,
        argon2_parallelism: result.argon2_params.parallelism,
        first_address: result.first_address,
        mnemonic_bytes: mnemonic.expose_secret().as_bytes().to_vec(),
    })
}

/// Response from wallet creation — all data needed for storage and display.
#[flutter_rust_bridge::frb]
pub struct WalletCreationResponse {
    /// Encrypted mnemonic (nonce || ciphertext || tag).
    pub encrypted_mnemonic: Vec<u8>,
    /// 16-byte Argon2id salt.
    pub salt: Vec<u8>,
    /// Argon2id memory cost in KiB.
    pub argon2_memory_kib: u32,
    /// Argon2id iterations.
    pub argon2_iterations: u32,
    /// Argon2id parallelism.
    pub argon2_parallelism: u32,
    /// First derived address (EIP-55 checksummed, non-sensitive).
    pub first_address: String,
    /// Mnemonic phrase as bytes — MUST be zeroized by caller after backup display.
    pub mnemonic_bytes: Vec<u8>,
}

/// Imports a wallet from an existing mnemonic phrase.
///
/// `phrase_bytes`: mnemonic as UTF-8 bytes.
/// `password`: password as bytes.
///
/// Returns: encrypted mnemonic + metadata.
pub fn import_wallet(
    phrase_bytes: Vec<u8>,
    password: Vec<u8>,
) -> Result<WalletImportResponse> {
    let result = manager::import_wallet(&phrase_bytes, &password)?;

    Ok(WalletImportResponse {
        encrypted_mnemonic: result.encrypted_mnemonic,
        salt: result.salt.to_vec(),
        argon2_memory_kib: result.argon2_params.memory_kib,
        argon2_iterations: result.argon2_params.iterations,
        argon2_parallelism: result.argon2_params.parallelism,
        first_address: result.first_address,
    })
}

/// Response from wallet import.
#[flutter_rust_bridge::frb]
pub struct WalletImportResponse {
    pub encrypted_mnemonic: Vec<u8>,
    pub salt: Vec<u8>,
    pub argon2_memory_kib: u32,
    pub argon2_iterations: u32,
    pub argon2_parallelism: u32,
    pub first_address: String,
}

/// Decrypts and returns the mnemonic phrase for backup verification.
///
/// SECURITY: Returned bytes must be zeroized by caller after display.
pub fn decrypt_mnemonic(
    password: Vec<u8>,
    encrypted_mnemonic: Vec<u8>,
    salt: Vec<u8>,
    memory_kib: u32,
    iterations: u32,
    parallelism: u32,
) -> Result<Vec<u8>> {
    if salt.len() != 16 {
        return Err(UnvaultError::WalletOperation(format!(
            "salt must be 16 bytes, got {}",
            salt.len()
        )));
    }

    let mut salt_arr = [0u8; 16];
    salt_arr.copy_from_slice(&salt);

    let params =
        crate::crypto::argon2::Argon2Params { memory_kib, iterations, parallelism };

    let decrypted =
        manager::decrypt_mnemonic(&password, &encrypted_mnemonic, &salt_arr, &params)?;

    Ok(decrypted.expose_secret().as_bytes().to_vec())
}

/// Derives Ethereum account addresses from a mnemonic.
///
/// `phrase_bytes`: mnemonic as UTF-8 bytes.
/// `count`: number of accounts to derive (0-based sequential).
///
/// Returns: list of EIP-55 checksummed addresses (non-sensitive, safe as String).
#[flutter_rust_bridge::frb(sync)]
pub fn derive_accounts(
    phrase_bytes: Vec<u8>,
    count: u32,
) -> Result<Vec<String>> {
    manager::derive_accounts_from_mnemonic(&phrase_bytes, count)
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_PASSWORD: &[u8] = b"test_password_secure_123";

    #[test]
    fn create_wallet_api_succeeds() {
        let response = create_wallet(TEST_PASSWORD.to_vec(), 12).unwrap();

        assert!(!response.encrypted_mnemonic.is_empty());
        assert_eq!(response.salt.len(), 16);
        assert!(response.first_address.starts_with("0x"));
        assert!(!response.mnemonic_bytes.is_empty());
    }

    #[test]
    fn create_wallet_invalid_word_count() {
        let result = create_wallet(TEST_PASSWORD.to_vec(), 15);
        assert!(result.is_err());
    }

    #[test]
    fn create_and_decrypt_wallet() {
        let response = create_wallet(TEST_PASSWORD.to_vec(), 12).unwrap();

        let decrypted = decrypt_mnemonic(
            TEST_PASSWORD.to_vec(),
            response.encrypted_mnemonic,
            response.salt,
            response.argon2_memory_kib,
            response.argon2_iterations,
            response.argon2_parallelism,
        )
        .unwrap();

        assert_eq!(decrypted, response.mnemonic_bytes);
    }

    #[test]
    fn import_wallet_api_succeeds() {
        let mnemonic = b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about".to_vec();

        let response = import_wallet(mnemonic, TEST_PASSWORD.to_vec()).unwrap();

        assert!(!response.encrypted_mnemonic.is_empty());
        assert!(response.first_address.starts_with("0x"));
    }

    #[test]
    fn derive_accounts_api_returns_addresses() {
        let mnemonic = b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about".to_vec();

        let addresses = derive_accounts(mnemonic, 3).unwrap();

        assert_eq!(addresses.len(), 3);
        for addr in &addresses {
            assert!(addr.starts_with("0x"));
            assert_eq!(addr.len(), 42);
        }
    }

    #[test]
    fn decrypt_mnemonic_invalid_salt_length() {
        let result = decrypt_mnemonic(
            b"password".to_vec(),
            vec![0; 28],
            vec![0; 8], // wrong length
            32 * 1024,
            2,
            1,
        );
        assert!(result.is_err());
    }
}
