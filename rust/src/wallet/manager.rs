#![allow(dead_code)]

use secrecy::{ExposeSecret, SecretBox};
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::crypto::{argon2, encryption, key_derivation, mnemonic};
use crate::error::Result;

/// Result of creating a new wallet, containing the encrypted mnemonic
/// and the parameters needed to decrypt it later.
pub struct WalletCreationResult {
    /// The encrypted mnemonic bytes (nonce || ciphertext || tag).
    pub encrypted_mnemonic: Vec<u8>,
    /// The salt used for Argon2id derivation.
    pub salt: [u8; 16],
    /// The Argon2id parameters used for key derivation.
    pub argon2_params: argon2::Argon2Params,
    /// The first derived account address (EIP-55 checksummed string).
    pub first_address: String,
}

/// Result of importing an existing wallet from a mnemonic phrase.
#[derive(Debug)]
pub struct WalletImportResult {
    /// The encrypted mnemonic bytes.
    pub encrypted_mnemonic: Vec<u8>,
    /// The salt used for Argon2id derivation.
    pub salt: [u8; 16],
    /// The Argon2id parameters used for key derivation.
    pub argon2_params: argon2::Argon2Params,
    /// The first derived account address (EIP-55 checksummed string).
    pub first_address: String,
}

/// A decrypted mnemonic phrase in bytes, wrapped for security.
#[derive(Zeroize, ZeroizeOnDrop)]
pub struct DecryptedMnemonic {
    pub(crate) phrase_bytes: Vec<u8>,
}

impl DecryptedMnemonic {
    pub fn as_bytes(&self) -> &[u8] {
        &self.phrase_bytes
    }
}

/// Creates a new wallet: generates mnemonic, encrypts it, derives first account.
///
/// Flow:
/// 1. Generate BIP-39 mnemonic (12 or 24 words)
/// 2. Derive encryption key from password via Argon2id
/// 3. Encrypt mnemonic with AES-256-GCM
/// 4. Derive first Ethereum account from mnemonic seed
/// 5. Return encrypted mnemonic + metadata (never plaintext mnemonic)
///
/// # Errors
/// - `MnemonicGeneration` if mnemonic generation fails.
/// - `Argon2Derivation` if password key derivation fails.
/// - `Encryption` if mnemonic encryption fails.
/// - `KeyDerivation` if account derivation fails.
pub fn create_wallet(
    password: &[u8],
    word_count: mnemonic::WordCount,
) -> Result<(WalletCreationResult, SecretBox<DecryptedMnemonic>)> {
    // 1. Generate mnemonic
    let secret_mnemonic = mnemonic::generate(word_count)?;
    let phrase_bytes = secret_mnemonic.expose_secret().as_bytes().to_vec();

    // 2. Derive encryption key from password
    let salt = argon2::generate_salt();
    let params = argon2::Argon2Params::safety_floor(); // Will be calibrated via API layer
    let derived_key = argon2::derive_key(password, &salt, &params)?;

    // 3. Encrypt mnemonic
    let encrypted_mnemonic = encryption::encrypt(derived_key.expose_secret().as_bytes(), &phrase_bytes)?;

    // 4. Derive seed and first account
    let seed = mnemonic::derive_seed(&phrase_bytes, b"")?;
    let first_account = key_derivation::derive_account(seed.expose_secret().as_bytes(), 0)?;
    let first_address = first_account.address.to_checksum(None);

    let result = WalletCreationResult {
        encrypted_mnemonic,
        salt,
        argon2_params: params,
        first_address,
    };

    let decrypted = SecretBox::new(Box::new(DecryptedMnemonic { phrase_bytes }));

    Ok((result, decrypted))
}

/// Imports a wallet from an existing mnemonic phrase.
///
/// Flow:
/// 1. Validate the mnemonic phrase
/// 2. Derive encryption key from password via Argon2id
/// 3. Encrypt mnemonic with AES-256-GCM
/// 4. Derive first Ethereum account
///
/// # Errors
/// - `InvalidMnemonic` if the phrase is invalid.
/// - `Argon2Derivation` / `Encryption` / `KeyDerivation` on subsequent failures.
pub fn import_wallet(
    phrase_bytes: &[u8],
    password: &[u8],
) -> Result<WalletImportResult> {
    // 1. Validate mnemonic
    mnemonic::validate(phrase_bytes)?;

    // 2. Derive encryption key from password
    let salt = argon2::generate_salt();
    let params = argon2::Argon2Params::safety_floor();
    let derived_key = argon2::derive_key(password, &salt, &params)?;

    // 3. Encrypt mnemonic
    let encrypted_mnemonic = encryption::encrypt(derived_key.expose_secret().as_bytes(), phrase_bytes)?;

    // 4. Derive first account
    let seed = mnemonic::derive_seed(phrase_bytes, b"")?;
    let first_account = key_derivation::derive_account(seed.expose_secret().as_bytes(), 0)?;
    let first_address = first_account.address.to_checksum(None);

    Ok(WalletImportResult {
        encrypted_mnemonic,
        salt,
        argon2_params: params,
        first_address,
    })
}

/// Decrypts the mnemonic from encrypted storage using the user's password.
///
/// # Errors
/// - `Argon2Derivation` if key derivation fails.
/// - `DecryptionFailed` if the password is wrong or data is corrupted.
pub fn decrypt_mnemonic(
    password: &[u8],
    encrypted_mnemonic: &[u8],
    salt: &[u8; 16],
    params: &argon2::Argon2Params,
) -> Result<SecretBox<DecryptedMnemonic>> {
    let derived_key = argon2::derive_key(password, salt, params)?;
    let plaintext = encryption::decrypt(derived_key.expose_secret().as_bytes(), encrypted_mnemonic)?;

    // Validate that the decrypted bytes form a valid mnemonic
    mnemonic::validate(&plaintext)?;

    Ok(SecretBox::new(Box::new(DecryptedMnemonic { phrase_bytes: plaintext })))
}

/// Derives Ethereum accounts from a decrypted mnemonic.
///
/// # Errors
/// - `InvalidMnemonic` if seed derivation fails.
/// - `KeyDerivation` if account derivation fails.
pub fn derive_accounts_from_mnemonic(
    phrase_bytes: &[u8],
    count: u32,
) -> Result<Vec<String>> {
    let seed = mnemonic::derive_seed(phrase_bytes, b"")?;
    let accounts = key_derivation::derive_accounts(seed.expose_secret().as_bytes(), count)?;

    Ok(accounts.iter().map(|a| a.address.to_checksum(None)).collect())
}

#[cfg(test)]
mod tests {
    use secrecy::ExposeSecret;

    use super::*;

    const TEST_PASSWORD: &[u8] = b"test_password_secure_123";

    use crate::error::UnvaultError;

    const TEST_MNEMONIC: &[u8] =
        b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    #[test]
    fn create_wallet_returns_valid_result() {
        let (result, mnemonic) = create_wallet(TEST_PASSWORD, mnemonic::WordCount::Words12).unwrap();

        assert!(!result.encrypted_mnemonic.is_empty());
        assert!(!result.first_address.is_empty());
        assert!(result.first_address.starts_with("0x"));
        assert_eq!(result.first_address.len(), 42);
        assert!(!mnemonic.expose_secret().as_bytes().is_empty());
    }

    #[test]
    fn create_wallet_mnemonic_is_valid() {
        let (_result, mnemonic) = create_wallet(TEST_PASSWORD, mnemonic::WordCount::Words12).unwrap();
        let phrase = mnemonic.expose_secret().as_bytes();

        assert!(mnemonic::validate(phrase).is_ok());
    }

    #[test]
    fn create_wallet_encrypted_mnemonic_differs_from_plaintext() {
        let (result, mnemonic) = create_wallet(TEST_PASSWORD, mnemonic::WordCount::Words12).unwrap();
        let phrase = mnemonic.expose_secret().as_bytes();

        assert_ne!(result.encrypted_mnemonic.as_slice(), phrase);
    }

    #[test]
    fn create_wallet_can_decrypt_with_correct_password() {
        let (result, original_mnemonic) =
            create_wallet(TEST_PASSWORD, mnemonic::WordCount::Words12).unwrap();

        let decrypted = decrypt_mnemonic(
            TEST_PASSWORD,
            &result.encrypted_mnemonic,
            &result.salt,
            &result.argon2_params,
        )
        .unwrap();

        assert_eq!(
            decrypted.expose_secret().as_bytes(),
            original_mnemonic.expose_secret().as_bytes()
        );
    }

    #[test]
    fn create_wallet_wrong_password_fails_decrypt() {
        let (result, _) = create_wallet(TEST_PASSWORD, mnemonic::WordCount::Words12).unwrap();

        let decryption_result = decrypt_mnemonic(
            b"wrong_password_entirely",
            &result.encrypted_mnemonic,
            &result.salt,
            &result.argon2_params,
        );

        assert!(decryption_result.is_err());
    }

    #[test]
    fn import_wallet_succeeds() {
        let result = import_wallet(TEST_MNEMONIC, TEST_PASSWORD).unwrap();

        assert!(!result.encrypted_mnemonic.is_empty());
        assert!(result.first_address.starts_with("0x"));
        assert_eq!(result.first_address.len(), 42);
    }

    #[test]
    fn import_wallet_invalid_mnemonic_fails() {
        let result = import_wallet(b"not a valid mnemonic phrase at all", TEST_PASSWORD);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidMnemonic(_)));
    }

    #[test]
    fn import_wallet_produces_correct_address() {
        let result = import_wallet(TEST_MNEMONIC, TEST_PASSWORD).unwrap();

        // Known address for "abandon...about" with no passphrase at index 0
        let expected = "0x9858EfFD232B4033E47d90003D41EC34EcaEda94";
        assert_eq!(result.first_address, expected);
    }

    #[test]
    fn import_wallet_can_decrypt_with_correct_password() {
        let result = import_wallet(TEST_MNEMONIC, TEST_PASSWORD).unwrap();

        let decrypted = decrypt_mnemonic(
            TEST_PASSWORD,
            &result.encrypted_mnemonic,
            &result.salt,
            &result.argon2_params,
        )
        .unwrap();

        assert_eq!(decrypted.expose_secret().as_bytes(), TEST_MNEMONIC);
    }

    #[test]
    fn derive_accounts_from_mnemonic_returns_correct_count() {
        let addresses = derive_accounts_from_mnemonic(TEST_MNEMONIC, 3).unwrap();
        assert_eq!(addresses.len(), 3);
    }

    #[test]
    fn derive_accounts_from_mnemonic_all_unique() {
        let addresses = derive_accounts_from_mnemonic(TEST_MNEMONIC, 5).unwrap();
        for i in 0..addresses.len() {
            for j in (i + 1)..addresses.len() {
                assert_ne!(addresses[i], addresses[j]);
            }
        }
    }

    #[test]
    fn derive_accounts_from_mnemonic_deterministic() {
        let a1 = derive_accounts_from_mnemonic(TEST_MNEMONIC, 3).unwrap();
        let a2 = derive_accounts_from_mnemonic(TEST_MNEMONIC, 3).unwrap();
        assert_eq!(a1, a2);
    }

    #[test]
    fn derive_accounts_zero_returns_empty() {
        let addresses = derive_accounts_from_mnemonic(TEST_MNEMONIC, 0).unwrap();
        assert!(addresses.is_empty());
    }
}
