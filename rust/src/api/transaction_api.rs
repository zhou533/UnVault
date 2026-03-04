//! FFI API for transaction construction and signing.
//!
//! SECURITY: Private keys are passed as `Vec<u8>` and never leave the Rust layer.
//! Only the signed raw transaction bytes are returned to Dart.

use alloy_primitives::{Address, U256};
use secrecy::ExposeSecret;

use crate::crypto::{key_derivation, mnemonic};
use crate::error::{Result, UnvaultError};
use crate::transaction::{builder, signer};

/// Builds and signs an EIP-1559 transaction.
///
/// SECURITY: The `private_key` is consumed by this function and used only for signing.
/// The signed raw transaction is returned — the private key never crosses back to Dart.
///
/// # Parameters
/// - `private_key`: 32-byte private key as bytes.
/// - `chain_id`: EIP-155 chain ID.
/// - `nonce`: sender's current nonce.
/// - `to`: recipient address as hex string (with 0x prefix), or empty for contract creation.
/// - `value_wei`: value in wei as a decimal string (to avoid overflow with u64).
/// - `input`: calldata bytes.
/// - `gas_limit`: gas limit.
/// - `max_fee_per_gas`: max fee per gas in wei.
/// - `max_priority_fee_per_gas`: max priority fee per gas in wei.
///
/// # Returns
/// `SignTransactionResponse` with raw tx bytes, tx hash, and sender address.
#[allow(clippy::too_many_arguments)]
pub fn sign_transaction(
    private_key: Vec<u8>,
    chain_id: u64,
    nonce: u64,
    to: String,
    value_wei: String,
    input: Vec<u8>,
    gas_limit: u64,
    max_fee_per_gas: u128,
    max_priority_fee_per_gas: u128,
) -> Result<SignTransactionResponse> {
    // Parse recipient address
    let to_addr = if to.is_empty() {
        None
    } else {
        Some(
            to.parse::<Address>()
                .map_err(|e| UnvaultError::TransactionBuild(format!("invalid to address: {e}")))?,
        )
    };

    // Parse value from decimal string to avoid u64 overflow
    let value = U256::from_str_radix(value_wei.trim_start_matches("0x"), 10)
        .map_err(|e| UnvaultError::TransactionBuild(format!("invalid value: {e}")))?;

    // Build unsigned transaction
    let params = builder::TransactionParams {
        chain_id,
        nonce,
        to: to_addr,
        value,
        input,
        gas_limit,
        max_fee_per_gas,
        max_priority_fee_per_gas,
    };

    let unsigned_tx = builder::build_eip1559(&params)?;

    // Sign the transaction
    let signed = signer::sign_eip1559(&private_key, &unsigned_tx)?;

    Ok(SignTransactionResponse {
        raw_tx: signed.raw_tx,
        tx_hash: signed.tx_hash.to_vec(),
        from: signed.from.to_checksum(None),
    })
}

/// Signs a transaction using a mnemonic phrase, keeping the private key entirely in Rust.
///
/// SECURITY: The private key is derived from the mnemonic in-memory, used for signing,
/// and zeroized on drop (via `DerivedKeyPair`'s `ZeroizeOnDrop` implementation).
/// The private key NEVER crosses the FFI boundary.
///
/// # Parameters
/// - `phrase_bytes`: BIP-39 mnemonic phrase as UTF-8 bytes.
/// - `account_index`: BIP-44 account index (0-based).
/// - Remaining params same as `sign_transaction`.
#[allow(clippy::too_many_arguments)]
pub fn sign_transaction_with_seed(
    phrase_bytes: Vec<u8>,
    account_index: u32,
    chain_id: u64,
    nonce: u64,
    to: String,
    value_wei: String,
    input: Vec<u8>,
    gas_limit: u64,
    max_fee_per_gas: u128,
    max_priority_fee_per_gas: u128,
) -> Result<SignTransactionResponse> {
    // 1. Derive seed from mnemonic phrase
    let seed = mnemonic::derive_seed(&phrase_bytes, b"")?;

    // 2. Derive account at the specified index
    let account = key_derivation::derive_account(seed.expose_secret().as_bytes(), account_index)?;

    // 3. Extract private key bytes (stays in Rust, zeroized on drop)
    let private_key = account.key_pair.expose_secret().as_bytes().to_vec();

    // 4. Delegate to existing sign_transaction
    sign_transaction(
        private_key,
        chain_id,
        nonce,
        to,
        value_wei,
        input,
        gas_limit,
        max_fee_per_gas,
        max_priority_fee_per_gas,
    )
}

/// Response from signing a transaction.
#[flutter_rust_bridge::frb]
pub struct SignTransactionResponse {
    /// RLP-encoded signed transaction bytes (ready for `eth_sendRawTransaction`).
    pub raw_tx: Vec<u8>,
    /// Transaction hash (32 bytes).
    pub tx_hash: Vec<u8>,
    /// Sender address (EIP-55 checksummed, non-sensitive).
    pub from: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_key() -> Vec<u8> {
        hex::decode("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80").unwrap()
    }

    #[test]
    fn sign_transaction_succeeds() {
        let response = sign_transaction(
            test_key(),
            1,
            0,
            "0x0000000000000000000000000000000000000000".into(),
            "1000000000000000000".into(), // 1 ETH
            vec![],
            21_000,
            30_000_000_000,
            1_500_000_000,
        )
        .unwrap();

        assert!(!response.raw_tx.is_empty());
        assert_eq!(response.tx_hash.len(), 32);
        assert!(response.from.starts_with("0x"));
    }

    #[test]
    fn sign_transaction_invalid_key() {
        let result = sign_transaction(
            vec![0; 16], // wrong length
            1,
            0,
            "0x0000000000000000000000000000000000000000".into(),
            "1000000000000000000".into(),
            vec![],
            21_000,
            30_000_000_000,
            1_500_000_000,
        );

        assert!(result.is_err());
    }

    #[test]
    fn sign_transaction_invalid_address() {
        let result = sign_transaction(
            test_key(),
            1,
            0,
            "not_an_address".into(),
            "1000000000000000000".into(),
            vec![],
            21_000,
            30_000_000_000,
            1_500_000_000,
        );

        assert!(result.is_err());
    }

    #[test]
    fn sign_transaction_contract_creation() {
        let response = sign_transaction(
            test_key(),
            1,
            0,
            "".into(), // empty = contract creation
            "0".into(),
            vec![0x60, 0x80, 0x60, 0x40],
            100_000,
            30_000_000_000,
            1_500_000_000,
        )
        .unwrap();

        assert!(!response.raw_tx.is_empty());
    }

    #[test]
    fn sign_transaction_zero_chain_id_fails() {
        let result = sign_transaction(
            test_key(),
            0, // invalid
            0,
            "0x0000000000000000000000000000000000000000".into(),
            "0".into(),
            vec![],
            21_000,
            30_000_000_000,
            1_500_000_000,
        );

        assert!(result.is_err());
    }

    #[test]
    fn sign_transaction_with_seed_succeeds() {
        let phrase = b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let result = sign_transaction_with_seed(
            phrase.to_vec(),
            0,
            1,  // Ethereum mainnet
            0,  // nonce
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045".to_string(),
            "1000000000000000000".to_string(), // 1 ETH
            vec![],
            21000,
            30_000_000_000,
            2_000_000_000,
        )
        .unwrap();

        assert!(!result.raw_tx.is_empty());
        assert_eq!(result.tx_hash.len(), 32);
        assert!(result.from.starts_with("0x"));
        assert_eq!(result.from.len(), 42);
    }

    #[test]
    fn sign_transaction_with_seed_different_index() {
        let phrase = b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
        let r0 = sign_transaction_with_seed(
            phrase.to_vec(), 0, 1, 0,
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045".to_string(),
            "0".to_string(), vec![], 21000, 30_000_000_000, 2_000_000_000,
        ).unwrap();

        let r1 = sign_transaction_with_seed(
            phrase.to_vec(), 1, 1, 0,
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045".to_string(),
            "0".to_string(), vec![], 21000, 30_000_000_000, 2_000_000_000,
        ).unwrap();

        // Different account indices should produce different sender addresses
        assert_ne!(r0.from, r1.from);
    }

    #[test]
    fn sign_transaction_with_seed_invalid_phrase_fails() {
        let result = sign_transaction_with_seed(
            b"not a valid mnemonic".to_vec(),
            0, 1, 0,
            "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045".to_string(),
            "0".to_string(), vec![], 21000, 30_000_000_000, 2_000_000_000,
        );
        assert!(result.is_err());
    }
}
