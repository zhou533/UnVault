#![allow(dead_code)]

use coins_bip39::{English, Mnemonic as CoinsMnemonic};
use rand::rngs::OsRng;
use secrecy::SecretBox;
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::error::{Result, UnvaultError};

/// Word count for mnemonic generation.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WordCount {
    /// 12-word mnemonic (128 bits entropy).
    Words12,
    /// 24-word mnemonic (256 bits entropy).
    Words24,
}

impl WordCount {
    fn to_count(self) -> usize {
        match self {
            WordCount::Words12 => 12,
            WordCount::Words24 => 24,
        }
    }
}

/// A BIP-39 mnemonic phrase stored as UTF-8 bytes.
///
/// SECURITY: Stored as `Vec<u8>`, never as `String` (String is immutable and may be interned).
/// No `Debug` or `Display` implementation to prevent accidental logging.
/// Implements `Zeroize + ZeroizeOnDrop` to clear memory on drop.
#[derive(Zeroize, ZeroizeOnDrop)]
pub struct MnemonicPhrase {
    phrase_bytes: Vec<u8>,
}

impl MnemonicPhrase {
    /// Access the phrase as a byte slice.
    pub fn as_bytes(&self) -> &[u8] {
        &self.phrase_bytes
    }
}

/// A BIP-39 mnemonic phrase wrapped in `Secret<T>` to prevent accidental exposure.
pub type SecretMnemonic = SecretBox<MnemonicPhrase>;

/// A 64-byte BIP-39 seed derived from a mnemonic phrase.
///
/// No `Debug` or `Display` implementation.
/// Implements `Zeroize + ZeroizeOnDrop`.
#[derive(Zeroize, ZeroizeOnDrop)]
pub struct SeedBytes(pub(crate) [u8; 64]);

impl SeedBytes {
    /// Access the seed as a byte slice.
    pub fn as_bytes(&self) -> &[u8] {
        &self.0
    }
}

/// Generates a new BIP-39 mnemonic with the given word count.
///
/// Uses `OsRng` (CSPRNG) for entropy generation — never `thread_rng`.
///
/// # Errors
/// - `MnemonicGeneration` if the underlying library fails.
pub fn generate(word_count: WordCount) -> Result<SecretMnemonic> {
    let mnemonic = CoinsMnemonic::<English>::new_with_count(&mut OsRng, word_count.to_count())
        .map_err(|e| UnvaultError::MnemonicGeneration(e.to_string()))?;

    // Extract phrase as bytes immediately, then let the CoinsMnemonic drop.
    // CoinsMnemonic doesn't implement Zeroize, so we minimize its lifetime.
    let phrase_string = mnemonic.to_phrase();
    let phrase_bytes = phrase_string.into_bytes();

    Ok(SecretBox::new(Box::new(MnemonicPhrase { phrase_bytes })))
}

/// Validates a BIP-39 mnemonic phrase.
///
/// `phrase_bytes` must be valid UTF-8 encoding of space-separated BIP-39 words.
///
/// # Errors
/// - `InvalidMnemonic` if the phrase is not a valid BIP-39 mnemonic.
pub fn validate(phrase_bytes: &[u8]) -> Result<()> {
    let phrase_str = std::str::from_utf8(phrase_bytes)
        .map_err(|_| UnvaultError::InvalidMnemonic("invalid UTF-8".into()))?;

    CoinsMnemonic::<English>::new_from_phrase(phrase_str)
        .map_err(|e| UnvaultError::InvalidMnemonic(e.to_string()))?;

    Ok(())
}

/// Derives a 64-byte BIP-39 seed from a mnemonic phrase and optional passphrase.
///
/// Both inputs are byte slices (never Strings) per FFI security rules.
///
/// # Errors
/// - `InvalidMnemonic` if the phrase is not valid UTF-8 or not a valid BIP-39 mnemonic.
/// - `KeyDerivation` if seed derivation fails.
pub fn derive_seed(phrase_bytes: &[u8], passphrase: &[u8]) -> Result<SecretBox<SeedBytes>> {
    let phrase_str = std::str::from_utf8(phrase_bytes)
        .map_err(|_| UnvaultError::InvalidMnemonic("invalid UTF-8".into()))?;

    let passphrase_str = std::str::from_utf8(passphrase)
        .map_err(|_| UnvaultError::InvalidMnemonic("invalid UTF-8 passphrase".into()))?;

    let mnemonic = CoinsMnemonic::<English>::new_from_phrase(phrase_str)
        .map_err(|e| UnvaultError::InvalidMnemonic(e.to_string()))?;

    let password = if passphrase_str.is_empty() { None } else { Some(passphrase_str) };

    let seed =
        mnemonic.to_seed(password).map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

    Ok(SecretBox::new(Box::new(SeedBytes(seed))))
}

#[cfg(test)]
mod tests {
    use secrecy::ExposeSecret;

    use super::*;

    /// BIP-39 test vector #1: all-zero entropy → "abandon ... about"
    const TEST_MNEMONIC_12: &[u8] =
        b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    /// BIP-39 test vector: 24-word all-zero entropy → "abandon ... art"
    const TEST_MNEMONIC_24: &[u8] =
        b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon art";

    #[test]
    fn generate_12_words() {
        let secret = generate(WordCount::Words12).unwrap();
        let phrase = secret.expose_secret();
        let words: Vec<&str> = std::str::from_utf8(phrase.as_bytes()).unwrap().split(' ').collect();
        assert_eq!(words.len(), 12);
    }

    #[test]
    fn generate_24_words() {
        let secret = generate(WordCount::Words24).unwrap();
        let phrase = secret.expose_secret();
        let words: Vec<&str> = std::str::from_utf8(phrase.as_bytes()).unwrap().split(' ').collect();
        assert_eq!(words.len(), 24);
    }

    #[test]
    fn generate_produces_valid_mnemonic() {
        let secret = generate(WordCount::Words12).unwrap();
        let phrase = secret.expose_secret();
        assert!(validate(phrase.as_bytes()).is_ok());
    }

    #[test]
    fn generate_produces_different_mnemonics() {
        let m1 = generate(WordCount::Words12).unwrap();
        let m2 = generate(WordCount::Words12).unwrap();
        assert_ne!(m1.expose_secret().as_bytes(), m2.expose_secret().as_bytes());
    }

    #[test]
    fn validate_valid_12_word_mnemonic() {
        assert!(validate(TEST_MNEMONIC_12).is_ok());
    }

    #[test]
    fn validate_valid_24_word_mnemonic() {
        assert!(validate(TEST_MNEMONIC_24).is_ok());
    }

    #[test]
    fn validate_invalid_mnemonic_garbage() {
        let result = validate(b"this is not a valid mnemonic phrase at all nope");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidMnemonic(_)));
    }

    #[test]
    fn validate_invalid_mnemonic_wrong_checksum() {
        // Valid words but wrong checksum (last word changed).
        let result = validate(
            b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon zone",
        );
        assert!(result.is_err());
    }

    #[test]
    fn validate_invalid_utf8() {
        let result = validate(&[0xFF, 0xFE, 0xFD]);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidMnemonic(_)));
    }

    #[test]
    fn derive_seed_deterministic() {
        let seed1 = derive_seed(TEST_MNEMONIC_12, b"").unwrap();
        let seed2 = derive_seed(TEST_MNEMONIC_12, b"").unwrap();
        assert_eq!(seed1.expose_secret().as_bytes(), seed2.expose_secret().as_bytes());
    }

    #[test]
    fn derive_seed_64_bytes() {
        let seed = derive_seed(TEST_MNEMONIC_12, b"").unwrap();
        assert_eq!(seed.expose_secret().as_bytes().len(), 64);
    }

    #[test]
    fn derive_seed_passphrase_changes_result() {
        let seed_no_pass = derive_seed(TEST_MNEMONIC_12, b"").unwrap();
        let seed_with_pass = derive_seed(TEST_MNEMONIC_12, b"TREZOR").unwrap();
        assert_ne!(
            seed_no_pass.expose_secret().as_bytes(),
            seed_with_pass.expose_secret().as_bytes()
        );
    }

    #[test]
    fn derive_seed_known_test_vector() {
        // BIP-39 test vector: "abandon ... about" with passphrase "TREZOR"
        // Expected seed from official test vectors.
        let expected_seed_hex = "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04";

        let seed = derive_seed(TEST_MNEMONIC_12, b"TREZOR").unwrap();
        let actual_hex = hex::encode(seed.expose_secret().as_bytes());

        assert_eq!(actual_hex, expected_seed_hex);
    }

    #[test]
    fn derive_seed_known_test_vector_24_words() {
        // BIP-39 test vector: "abandon ... art" with passphrase "TREZOR"
        let expected_seed_hex = "bda85446c68413707090a52022edd26a1c9462295029f2e60cd7c4f2bbd3097170af7a4d73245cafa9c3cca8d561a7c3de6f5d4a10be8ed2a5e608d68f92fcc8";

        let seed = derive_seed(TEST_MNEMONIC_24, b"TREZOR").unwrap();
        let actual_hex = hex::encode(seed.expose_secret().as_bytes());

        assert_eq!(actual_hex, expected_seed_hex);
    }

    #[test]
    fn derive_seed_invalid_mnemonic_fails() {
        let result = derive_seed(b"invalid mnemonic phrase", b"");
        assert!(result.is_err());
    }
}
