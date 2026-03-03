#![allow(dead_code)]

use alloy_primitives::Address;
use coins_bip32::prelude::*;
use secrecy::SecretBox;
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::error::{Result, UnvaultError};

/// BIP-44 derivation path prefix for Ethereum: m/44'/60'/0'/0
const ETH_BIP44_PREFIX: &str = "m/44'/60'/0'/0";

/// A 32-byte private key derived from HD key derivation.
///
/// No `Debug` or `Display` implementation.
/// Implements `Zeroize + ZeroizeOnDrop`.
#[derive(Zeroize, ZeroizeOnDrop)]
pub struct DerivedKeyPair {
    pub(crate) private_key: [u8; 32],
}

impl DerivedKeyPair {
    /// Access the private key as a byte slice.
    pub fn as_bytes(&self) -> &[u8] {
        &self.private_key
    }
}

/// A derived Ethereum account with key pair and EIP-55 checksummed address.
pub struct DerivedAccount {
    /// The derived private key, wrapped in SecretBox for protection.
    pub key_pair: SecretBox<DerivedKeyPair>,
    /// The EIP-55 checksummed Ethereum address.
    pub address: Address,
}

/// Derives a single Ethereum account from a BIP-39 seed at the given index.
///
/// Uses BIP-44 path: `m/44'/60'/0'/0/{index}`
///
/// # Errors
/// - `KeyDerivation` if the seed is invalid or derivation fails.
pub fn derive_account(seed: &[u8], index: u32) -> Result<DerivedAccount> {
    let path = format!("{ETH_BIP44_PREFIX}/{index}");

    let root = XPriv::root_from_seed(seed, None)
        .map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

    let child =
        root.derive_path(path.as_str()).map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

    extract_account(&child)
}

/// Derives multiple Ethereum accounts for indices 0..count.
///
/// More efficient than calling [`derive_account`] in a loop because
/// the parent key at `m/44'/60'/0'/0` is derived only once.
///
/// # Errors
/// - `KeyDerivation` if the seed is invalid or any derivation fails.
pub fn derive_accounts(seed: &[u8], count: u32) -> Result<Vec<DerivedAccount>> {
    let root = XPriv::root_from_seed(seed, None)
        .map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

    let parent = root
        .derive_path(ETH_BIP44_PREFIX)
        .map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

    let mut accounts = Vec::with_capacity(count as usize);
    for i in 0..count {
        let child =
            parent.derive_child(i).map_err(|e| UnvaultError::KeyDerivation(e.to_string()))?;

        accounts.push(extract_account(&child)?);
    }

    Ok(accounts)
}

/// Extracts a [`DerivedAccount`] from an [`XPriv`] key.
fn extract_account(xpriv: &XPriv) -> Result<DerivedAccount> {
    let signing_key: &SigningKey = xpriv.as_ref();

    let key_bytes = signing_key.to_bytes();
    let mut private_key = [0u8; 32];
    private_key.copy_from_slice(&key_bytes);

    let verifying_key = signing_key.verifying_key();
    let address = pubkey_to_address(verifying_key);

    Ok(DerivedAccount {
        key_pair: SecretBox::new(Box::new(DerivedKeyPair { private_key })),
        address,
    })
}

/// Converts an ECDSA verifying key to an Ethereum address.
///
/// Process: uncompressed pubkey (64 bytes, without 0x04 prefix) → keccak256 → last 20 bytes.
fn pubkey_to_address(verifying_key: &VerifyingKey) -> Address {
    let encoded_point = verifying_key.to_encoded_point(false);
    let uncompressed = encoded_point.as_bytes();
    // Skip the 0x04 prefix byte → 64 bytes of X || Y coordinates.
    let pubkey_bytes = &uncompressed[1..];

    let hash = alloy_primitives::keccak256(pubkey_bytes);
    Address::from_slice(&hash[12..])
}

#[cfg(test)]
mod tests {
    use secrecy::ExposeSecret;

    use super::*;

    /// BIP-39 test vector seed: "abandon...about" with passphrase "TREZOR".
    fn test_seed() -> Vec<u8> {
        hex::decode(
            "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531\
             f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
        )
        .unwrap()
    }

    #[test]
    fn derive_account_returns_valid_address() {
        let seed = test_seed();
        let account = derive_account(&seed, 0).unwrap();

        let addr_str = format!("{}", account.address);
        assert!(addr_str.starts_with("0x"));
        assert_eq!(addr_str.len(), 42); // "0x" + 40 hex chars
    }

    #[test]
    fn derive_account_deterministic() {
        let seed = test_seed();
        let a1 = derive_account(&seed, 0).unwrap();
        let a2 = derive_account(&seed, 0).unwrap();

        assert_eq!(a1.address, a2.address);
        assert_eq!(a1.key_pair.expose_secret().as_bytes(), a2.key_pair.expose_secret().as_bytes());
    }

    #[test]
    fn derive_account_different_indices_produce_different_results() {
        let seed = test_seed();
        let a0 = derive_account(&seed, 0).unwrap();
        let a1 = derive_account(&seed, 1).unwrap();

        assert_ne!(a0.address, a1.address);
        assert_ne!(a0.key_pair.expose_secret().as_bytes(), a1.key_pair.expose_secret().as_bytes());
    }

    #[test]
    fn derive_account_private_key_is_32_bytes() {
        let seed = test_seed();
        let account = derive_account(&seed, 0).unwrap();
        assert_eq!(account.key_pair.expose_secret().as_bytes().len(), 32);
    }

    #[test]
    fn derive_accounts_returns_correct_count() {
        let seed = test_seed();
        let accounts = derive_accounts(&seed, 3).unwrap();
        assert_eq!(accounts.len(), 3);
    }

    #[test]
    fn derive_accounts_matches_individual_derivation() {
        let seed = test_seed();
        let batch = derive_accounts(&seed, 3).unwrap();

        for (i, batch_account) in batch.iter().enumerate() {
            let individual = derive_account(&seed, i as u32).unwrap();
            assert_eq!(batch_account.address, individual.address);
            assert_eq!(
                batch_account.key_pair.expose_secret().as_bytes(),
                individual.key_pair.expose_secret().as_bytes()
            );
        }
    }

    #[test]
    fn derive_accounts_all_unique() {
        let seed = test_seed();
        let accounts = derive_accounts(&seed, 5).unwrap();

        for i in 0..accounts.len() {
            for j in (i + 1)..accounts.len() {
                assert_ne!(accounts[i].address, accounts[j].address);
            }
        }
    }

    #[test]
    fn derive_account_empty_seed_fails() {
        let err = derive_account(&[], 0).err().expect("should fail");
        assert!(matches!(err, UnvaultError::KeyDerivation(_)));
    }

    #[test]
    fn derive_account_short_seed_fails() {
        let err = derive_account(&[1u8; 8], 0).err().expect("should fail");
        assert!(matches!(err, UnvaultError::KeyDerivation(_)));
    }

    #[test]
    fn address_is_eip55_checksummed() {
        let seed = test_seed();
        let account = derive_account(&seed, 0).unwrap();
        let addr_str = format!("{}", account.address);

        // EIP-55 addresses have mixed case in the hex part.
        let hex_part = &addr_str[2..];
        let has_upper = hex_part.chars().any(|c| c.is_ascii_uppercase());
        let has_lower = hex_part.chars().any(|c| c.is_ascii_lowercase());

        // A valid EIP-55 address with non-trivial bytes will have mixed case.
        assert!(has_upper && has_lower, "expected mixed-case EIP-55 address, got: {addr_str}");
    }

    #[test]
    fn derive_accounts_empty_returns_empty() {
        let seed = test_seed();
        let accounts = derive_accounts(&seed, 0).unwrap();
        assert!(accounts.is_empty());
    }

    #[test]
    fn derive_account_known_vector() {
        // BIP-39 test vector: "abandon...about" + passphrase "TREZOR"
        // Seed: c55257c360c07c72...
        // At m/44'/60'/0'/0/0:
        let seed = test_seed();
        let account = derive_account(&seed, 0).unwrap();

        let expected_addr = "0x9c32F71D4DB8Fb9e1A58B0a80dF79935e7256FA6";
        let expected_pk = "62f1d86b246c81bdd8f6c166d56896a4a5e1eddbcaebe06480e5c0bc74c28224";

        assert_eq!(account.address.to_checksum(None), expected_addr);
        assert_eq!(hex::encode(account.key_pair.expose_secret().as_bytes()), expected_pk);
    }

    #[test]
    fn derive_account_known_vector_index_1() {
        let seed = test_seed();
        let account = derive_account(&seed, 1).unwrap();

        let expected_addr = "0x7AF7283bd1462C3b957e8FAc28Dc19cBbF2FAdfe";
        assert_eq!(account.address.to_checksum(None), expected_addr);
    }
}
