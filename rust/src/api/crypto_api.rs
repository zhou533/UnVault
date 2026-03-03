//! FFI API for cryptographic operations.
//!
//! Thin wrappers over domain modules. All sensitive data crosses the FFI
//! boundary as `Vec<u8>` / `Uint8List` — NEVER as String.

use secrecy::ExposeSecret;

use crate::crypto::{argon2, encryption, mnemonic};
use crate::error::{Result, UnvaultError};

/// Generates a new BIP-39 mnemonic and returns it as bytes.
///
/// `word_count`: 12 or 24.
///
/// Returns: mnemonic phrase as UTF-8 bytes (space-separated words).
///
/// SECURITY: The caller receives raw bytes — must be zeroized after use on the Dart side.
#[flutter_rust_bridge::frb(sync)]
pub fn generate_mnemonic(word_count: u8) -> Result<Vec<u8>> {
    let wc = match word_count {
        12 => mnemonic::WordCount::Words12,
        24 => mnemonic::WordCount::Words24,
        _ => return Err(UnvaultError::MnemonicGeneration("word_count must be 12 or 24".into())),
    };

    let secret = mnemonic::generate(wc)?;
    Ok(secret.expose_secret().as_bytes().to_vec())
}

/// Validates a BIP-39 mnemonic phrase.
///
/// `phrase_bytes`: mnemonic phrase as UTF-8 bytes.
///
/// Returns: `true` if valid.
#[flutter_rust_bridge::frb(sync)]
pub fn validate_mnemonic(phrase_bytes: Vec<u8>) -> Result<bool> {
    match mnemonic::validate(&phrase_bytes) {
        Ok(()) => Ok(true),
        Err(UnvaultError::InvalidMnemonic(_)) => Ok(false),
        Err(e) => Err(e),
    }
}

/// Derives a 64-byte BIP-39 seed from a mnemonic phrase and optional passphrase.
///
/// Both inputs are byte slices — NEVER String.
///
/// Returns: 64-byte seed.
pub fn derive_seed(phrase_bytes: Vec<u8>, passphrase: Vec<u8>) -> Result<Vec<u8>> {
    let seed = mnemonic::derive_seed(&phrase_bytes, &passphrase)?;
    Ok(seed.expose_secret().as_bytes().to_vec())
}

/// Generates a random 16-byte salt for Argon2id.
#[flutter_rust_bridge::frb(sync)]
pub fn generate_salt() -> Vec<u8> {
    argon2::generate_salt().to_vec()
}

/// Derives a 32-byte encryption key from password + salt via Argon2id.
///
/// `password`: password as bytes.
/// `salt`: 16-byte salt.
/// `memory_kib`, `iterations`, `parallelism`: Argon2id parameters.
///
/// Returns: 32-byte derived key.
pub fn derive_key(
    password: Vec<u8>,
    salt: Vec<u8>,
    memory_kib: u32,
    iterations: u32,
    parallelism: u32,
) -> Result<Vec<u8>> {
    if salt.len() != 16 {
        return Err(UnvaultError::InvalidArgon2Params(format!(
            "salt must be 16 bytes, got {}",
            salt.len()
        )));
    }

    let mut salt_arr = [0u8; 16];
    salt_arr.copy_from_slice(&salt);

    let params = argon2::Argon2Params { memory_kib, iterations, parallelism };

    let key = argon2::derive_key(&password, &salt_arr, &params)?;
    Ok(key.expose_secret().as_bytes().to_vec())
}

/// Calibrates Argon2id parameters for the current device.
///
/// Returns: (memory_kib, iterations, parallelism).
pub fn calibrate_argon2(target_min_ms: u64, target_max_ms: u64) -> Result<(u32, u32, u32)> {
    let params = argon2::calibrate((target_min_ms, target_max_ms))?;
    Ok((params.memory_kib, params.iterations, params.parallelism))
}

/// Encrypts data with AES-256-GCM.
///
/// `key`: 32-byte encryption key.
/// `plaintext`: data to encrypt.
///
/// Returns: `nonce(12) || ciphertext || tag(16)`.
#[flutter_rust_bridge::frb(sync)]
pub fn encrypt(key: Vec<u8>, plaintext: Vec<u8>) -> Result<Vec<u8>> {
    encryption::encrypt(&key, &plaintext)
}

/// Decrypts data with AES-256-GCM.
///
/// `key`: 32-byte encryption key.
/// `ciphertext`: data as produced by `encrypt`.
///
/// Returns: decrypted plaintext bytes.
#[flutter_rust_bridge::frb(sync)]
pub fn decrypt(key: Vec<u8>, ciphertext: Vec<u8>) -> Result<Vec<u8>> {
    encryption::decrypt(&key, &ciphertext)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_mnemonic_12_words() {
        let bytes = generate_mnemonic(12).unwrap();
        let phrase = std::str::from_utf8(&bytes).unwrap();
        assert_eq!(phrase.split(' ').count(), 12);
    }

    #[test]
    fn generate_mnemonic_24_words() {
        let bytes = generate_mnemonic(24).unwrap();
        let phrase = std::str::from_utf8(&bytes).unwrap();
        assert_eq!(phrase.split(' ').count(), 24);
    }

    #[test]
    fn generate_mnemonic_invalid_count() {
        assert!(generate_mnemonic(15).is_err());
    }

    #[test]
    fn validate_mnemonic_valid() {
        let bytes = generate_mnemonic(12).unwrap();
        assert!(validate_mnemonic(bytes).unwrap());
    }

    #[test]
    fn validate_mnemonic_invalid() {
        let invalid = b"not a valid mnemonic at all nope".to_vec();
        assert!(!validate_mnemonic(invalid).unwrap());
    }

    #[test]
    fn derive_seed_returns_64_bytes() {
        let mnemonic = generate_mnemonic(12).unwrap();
        let seed = derive_seed(mnemonic, vec![]).unwrap();
        assert_eq!(seed.len(), 64);
    }

    #[test]
    fn generate_salt_returns_16_bytes() {
        let salt = generate_salt();
        assert_eq!(salt.len(), 16);
    }

    #[test]
    fn derive_key_roundtrip() {
        let password = b"test_password".to_vec();
        let salt = generate_salt();
        let key = derive_key(password, salt, 32 * 1024, 2, 1).unwrap();
        assert_eq!(key.len(), 32);
    }

    #[test]
    fn derive_key_invalid_salt_length() {
        let result = derive_key(b"pass".to_vec(), vec![0; 8], 32 * 1024, 2, 1);
        assert!(result.is_err());
    }

    #[test]
    fn encrypt_decrypt_roundtrip() {
        let key = vec![42u8; 32];
        let plaintext = b"hello unvault FFI".to_vec();

        let ciphertext = encrypt(key.clone(), plaintext.clone()).unwrap();
        let decrypted = decrypt(key, ciphertext).unwrap();

        assert_eq!(decrypted, plaintext);
    }
}
