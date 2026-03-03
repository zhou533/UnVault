#![allow(dead_code)]
// Suppress deprecation from aes-gcm 0.10 using generic-array 0.x internally.
#![allow(deprecated)]

use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use rand::rngs::OsRng;
use rand::RngCore;

use crate::error::{Result, UnvaultError};

/// AES-256-GCM nonce size in bytes.
const NONCE_SIZE: usize = 12;

/// AES-256-GCM authentication tag size in bytes.
const TAG_SIZE: usize = 16;

/// Required key size for AES-256 (32 bytes / 256 bits).
const KEY_SIZE: usize = 32;

/// Encrypts plaintext using AES-256-GCM with a random nonce.
///
/// Output format: `nonce (12 bytes) || ciphertext || tag (16 bytes)`
///
/// The nonce is generated from `OsRng` (CSPRNG). Each call produces
/// a unique nonce — counter-mode nonce generation is avoided because
/// mobile state may be lost between app restarts.
///
/// # Errors
/// - `InvalidKeyLength` if `key` is not exactly 32 bytes.
/// - `Encryption` if the cipher operation fails.
pub fn encrypt(key: &[u8], plaintext: &[u8]) -> Result<Vec<u8>> {
    if key.len() != KEY_SIZE {
        return Err(UnvaultError::InvalidKeyLength { expected: KEY_SIZE, actual: key.len() });
    }

    let mut nonce_bytes = [0u8; NONCE_SIZE];
    OsRng.fill_bytes(&mut nonce_bytes);

    let cipher =
        Aes256Gcm::new_from_slice(key).map_err(|e| UnvaultError::Encryption(e.to_string()))?;
    let nonce = Nonce::from_slice(&nonce_bytes);

    // aes-gcm appends the 16-byte tag to the ciphertext.
    let ciphertext_with_tag =
        cipher.encrypt(nonce, plaintext).map_err(|e| UnvaultError::Encryption(e.to_string()))?;

    // Output: nonce || ciphertext || tag
    let mut output = Vec::with_capacity(NONCE_SIZE + ciphertext_with_tag.len());
    output.extend_from_slice(&nonce_bytes);
    output.extend_from_slice(&ciphertext_with_tag);

    Ok(output)
}

/// Decrypts data produced by [`encrypt`].
///
/// Expected input format: `nonce (12 bytes) || ciphertext || tag (16 bytes)`
///
/// # Errors
/// - `InvalidKeyLength` if `key` is not exactly 32 bytes.
/// - `DecryptionFailed` if the data is too short, the tag doesn't verify,
///   or the key is incorrect.
pub fn decrypt(key: &[u8], data: &[u8]) -> Result<Vec<u8>> {
    if key.len() != KEY_SIZE {
        return Err(UnvaultError::InvalidKeyLength { expected: KEY_SIZE, actual: key.len() });
    }

    // Minimum valid data: nonce (12) + tag (16) = 28 bytes (empty plaintext).
    if data.len() < NONCE_SIZE + TAG_SIZE {
        return Err(UnvaultError::DecryptionFailed);
    }

    let (nonce_bytes, ciphertext_with_tag) = data.split_at(NONCE_SIZE);

    let cipher =
        Aes256Gcm::new_from_slice(key).map_err(|e| UnvaultError::Encryption(e.to_string()))?;
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher.decrypt(nonce, ciphertext_with_tag).map_err(|_| UnvaultError::DecryptionFailed)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_key() -> [u8; 32] {
        [0x42u8; 32]
    }

    #[test]
    fn encrypt_decrypt_roundtrip() {
        let key = test_key();
        let plaintext = b"hello, unvault!";

        let encrypted = encrypt(&key, plaintext).unwrap();
        let decrypted = decrypt(&key, &encrypted).unwrap();

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn encrypt_output_format() {
        let key = test_key();
        let plaintext = b"test data";

        let encrypted = encrypt(&key, plaintext).unwrap();

        // Output length: nonce(12) + plaintext(9) + tag(16) = 37
        assert_eq!(encrypted.len(), NONCE_SIZE + plaintext.len() + TAG_SIZE);
    }

    #[test]
    fn encrypt_empty_plaintext() {
        let key = test_key();
        let encrypted = encrypt(&key, b"").unwrap();

        // nonce(12) + tag(16) = 28
        assert_eq!(encrypted.len(), NONCE_SIZE + TAG_SIZE);

        let decrypted = decrypt(&key, &encrypted).unwrap();
        assert!(decrypted.is_empty());
    }

    #[test]
    fn encrypt_produces_unique_nonces() {
        let key = test_key();
        let plaintext = b"same input";

        let enc1 = encrypt(&key, plaintext).unwrap();
        let enc2 = encrypt(&key, plaintext).unwrap();

        // The nonce (first 12 bytes) should differ between encryptions.
        assert_ne!(&enc1[..NONCE_SIZE], &enc2[..NONCE_SIZE]);
        // And therefore the full ciphertext differs.
        assert_ne!(enc1, enc2);
    }

    #[test]
    fn decrypt_wrong_key_fails() {
        let key = test_key();
        let wrong_key = [0xFFu8; 32];
        let plaintext = b"secret data";

        let encrypted = encrypt(&key, plaintext).unwrap();
        let result = decrypt(&wrong_key, &encrypted);

        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::DecryptionFailed));
    }

    #[test]
    fn encrypt_short_key_rejected() {
        let short_key = [0u8; 16];
        let result = encrypt(&short_key, b"data");

        assert!(result.is_err());
        match result.unwrap_err() {
            UnvaultError::InvalidKeyLength { expected, actual } => {
                assert_eq!(expected, 32);
                assert_eq!(actual, 16);
            }
            e => panic!("unexpected error variant: {e}"),
        }
    }

    #[test]
    fn decrypt_short_key_rejected() {
        let short_key = [0u8; 16];
        let result = decrypt(&short_key, &[0u8; 28]);

        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidKeyLength { .. }));
    }

    #[test]
    fn decrypt_too_short_data_fails() {
        let key = test_key();

        // Less than nonce(12) + tag(16) = 28 bytes.
        let result = decrypt(&key, &[0u8; 10]);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::DecryptionFailed));
    }

    #[test]
    fn decrypt_corrupted_ciphertext_fails() {
        let key = test_key();
        let plaintext = b"important data";

        let mut encrypted = encrypt(&key, plaintext).unwrap();

        // Corrupt one byte in the ciphertext region (after the nonce).
        let corrupt_idx = NONCE_SIZE + 2;
        encrypted[corrupt_idx] ^= 0xFF;

        let result = decrypt(&key, &encrypted);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::DecryptionFailed));
    }

    #[test]
    fn decrypt_corrupted_tag_fails() {
        let key = test_key();
        let plaintext = b"tagged data";

        let mut encrypted = encrypt(&key, plaintext).unwrap();

        // Corrupt the last byte (part of the tag).
        let last = encrypted.len() - 1;
        encrypted[last] ^= 0xFF;

        let result = decrypt(&key, &encrypted);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::DecryptionFailed));
    }

    #[test]
    fn decrypt_corrupted_nonce_fails() {
        let key = test_key();
        let plaintext = b"nonce test";

        let mut encrypted = encrypt(&key, plaintext).unwrap();

        // Corrupt the nonce (first byte).
        encrypted[0] ^= 0xFF;

        let result = decrypt(&key, &encrypted);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::DecryptionFailed));
    }

    #[test]
    fn roundtrip_large_data() {
        let key = test_key();
        let plaintext = vec![0xAB; 65536]; // 64 KiB

        let encrypted = encrypt(&key, &plaintext).unwrap();
        let decrypted = decrypt(&key, &encrypted).unwrap();

        assert_eq!(decrypted, plaintext);
    }

    mod proptest_encryption {
        use super::*;
        use proptest::prelude::*;

        proptest! {
            #[test]
            fn roundtrip_any_input(plaintext in proptest::collection::vec(any::<u8>(), 0..4096)) {
                let key = [42u8; 32];
                let encrypted = encrypt(&key, &plaintext).unwrap();
                let decrypted = decrypt(&key, &encrypted).unwrap();
                prop_assert_eq!(plaintext, decrypted);
            }

            #[test]
            fn output_length_invariant(plaintext in proptest::collection::vec(any::<u8>(), 0..4096)) {
                let key = [42u8; 32];
                let encrypted = encrypt(&key, &plaintext).unwrap();
                prop_assert_eq!(encrypted.len(), NONCE_SIZE + plaintext.len() + TAG_SIZE);
            }
        }
    }
}
