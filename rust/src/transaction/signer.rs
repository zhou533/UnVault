#![allow(dead_code)]

use alloy_consensus::transaction::RlpEcdsaEncodableTx;
use alloy_consensus::TxEip1559;
use alloy_network::TxSignerSync;
use alloy_primitives::Address;
use alloy_signer_local::PrivateKeySigner;
use zeroize::Zeroize;

use crate::error::{Result, UnvaultError};

/// Result of signing a transaction: the RLP-encoded signed transaction bytes.
///
/// This is the raw transaction ready for broadcast via `eth_sendRawTransaction`.
#[derive(Debug)]
pub struct SignedTransaction {
    /// RLP-encoded signed transaction bytes (ready for broadcast).
    pub raw_tx: Vec<u8>,
    /// The transaction hash.
    pub tx_hash: [u8; 32],
    /// The sender address (recovered from signature).
    pub from: Address,
}

/// Signs an EIP-1559 transaction with the given private key.
///
/// SECURITY:
/// - Private key never leaves this function.
/// - The key material is zeroized after signing.
/// - Only the signed raw transaction is returned to the caller.
///
/// # Errors
/// - `TransactionSign` if the private key is invalid or signing fails.
pub fn sign_eip1559(private_key: &[u8], tx: &TxEip1559) -> Result<SignedTransaction> {
    if private_key.len() != 32 {
        return Err(UnvaultError::TransactionSign("private key must be 32 bytes".into()));
    }

    // Copy key bytes so we can zeroize after use.
    let mut key_bytes = [0u8; 32];
    key_bytes.copy_from_slice(private_key);

    let signer = PrivateKeySigner::from_slice(&key_bytes)
        .map_err(|e| UnvaultError::TransactionSign(e.to_string()))?;

    // Zeroize the copy immediately — signer has its own internal copy.
    key_bytes.zeroize();

    let from = signer.address();

    // Sign the transaction (produces an ECDSA signature).
    let mut tx_clone = tx.clone();
    let signature = signer
        .sign_transaction_sync(&mut tx_clone)
        .map_err(|e: alloy_signer::Error| UnvaultError::TransactionSign(e.to_string()))?;

    // Encode the signed transaction to EIP-2718 envelope bytes for broadcast.
    let encoded_len = tx.eip2718_encoded_length(&signature);
    let mut raw_tx = Vec::with_capacity(encoded_len);
    tx.eip2718_encode(&signature, &mut raw_tx);

    let tx_hash: [u8; 32] = tx.tx_hash(&signature).into();

    Ok(SignedTransaction { raw_tx, tx_hash, from })
}

#[cfg(test)]
mod tests {
    use alloy_primitives::U256;

    use super::*;
    use crate::transaction::builder::{build_eip1559, TransactionParams};

    fn test_key() -> [u8; 32] {
        // Deterministic test key — NEVER use in production.
        hex::decode("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
            .unwrap()
            .try_into()
            .unwrap()
    }

    fn test_tx() -> TxEip1559 {
        let params = TransactionParams {
            chain_id: 1,
            nonce: 0,
            to: Some(Address::ZERO),
            value: U256::from(1_000_000_000_000_000_000u128),
            input: vec![],
            gas_limit: 21_000,
            max_fee_per_gas: 30_000_000_000,
            max_priority_fee_per_gas: 1_500_000_000,
        };
        build_eip1559(&params).unwrap()
    }

    #[test]
    fn sign_eip1559_produces_valid_result() {
        let key = test_key();
        let tx = test_tx();

        let signed = sign_eip1559(&key, &tx).unwrap();

        assert!(!signed.raw_tx.is_empty());
        assert_ne!(signed.tx_hash, [0u8; 32]);
        assert_ne!(signed.from, Address::ZERO);
    }

    #[test]
    fn sign_eip1559_deterministic() {
        let key = test_key();
        let tx = test_tx();

        let s1 = sign_eip1559(&key, &tx).unwrap();
        let s2 = sign_eip1559(&key, &tx).unwrap();

        assert_eq!(s1.raw_tx, s2.raw_tx);
        assert_eq!(s1.tx_hash, s2.tx_hash);
        assert_eq!(s1.from, s2.from);
    }

    #[test]
    fn sign_eip1559_invalid_key_length() {
        let short_key = [0u8; 16];
        let tx = test_tx();

        let result = sign_eip1559(&short_key, &tx);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::TransactionSign(_)));
    }

    #[test]
    fn sign_eip1559_zero_key_fails() {
        let zero_key = [0u8; 32];
        let tx = test_tx();

        let result = sign_eip1559(&zero_key, &tx);
        assert!(result.is_err());
    }

    #[test]
    fn sign_eip1559_from_matches_key() {
        let key = test_key();
        let tx = test_tx();

        let signer = PrivateKeySigner::from_slice(&key).unwrap();
        let expected_addr = signer.address();

        let signed = sign_eip1559(&key, &tx).unwrap();
        assert_eq!(signed.from, expected_addr);
    }
}
