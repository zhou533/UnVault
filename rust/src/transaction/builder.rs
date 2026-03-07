#![allow(dead_code)]

use alloy_consensus::{TxEip1559, TxLegacy};
use alloy_primitives::{Address, Bytes, ChainId, TxKind, U256};

use crate::error::{Result, UnvaultError};

/// Parameters for building an EIP-1559 transaction.
#[derive(Debug, Clone)]
pub struct TransactionParams {
    /// Target chain ID (EIP-155 replay protection).
    pub chain_id: ChainId,
    /// Sender's current nonce.
    pub nonce: u64,
    /// Recipient address (None for contract creation).
    pub to: Option<Address>,
    /// Value to transfer in wei.
    pub value: U256,
    /// Calldata for the transaction.
    pub input: Vec<u8>,
    /// Gas limit.
    pub gas_limit: u64,
    /// Maximum fee per gas (in wei).
    pub max_fee_per_gas: u128,
    /// Maximum priority fee per gas (in wei).
    pub max_priority_fee_per_gas: u128,
}

impl TransactionParams {
    /// Validates transaction parameters before building.
    pub fn validate(&self) -> Result<()> {
        if self.chain_id == 0 {
            return Err(UnvaultError::TransactionBuild("chain_id must be non-zero".into()));
        }
        if self.gas_limit == 0 {
            return Err(UnvaultError::TransactionBuild("gas_limit must be non-zero".into()));
        }
        if self.max_fee_per_gas == 0 {
            return Err(UnvaultError::TransactionBuild("max_fee_per_gas must be non-zero".into()));
        }
        if self.max_priority_fee_per_gas > self.max_fee_per_gas {
            return Err(UnvaultError::TransactionBuild(
                "max_priority_fee_per_gas cannot exceed max_fee_per_gas".into(),
            ));
        }
        Ok(())
    }
}

/// Builds an unsigned EIP-1559 transaction from the given parameters.
///
/// # Errors
/// - `TransactionBuild` if parameters are invalid.
pub fn build_eip1559(params: &TransactionParams) -> Result<TxEip1559> {
    params.validate()?;

    let to = match params.to {
        Some(addr) => TxKind::Call(addr),
        None => TxKind::Create,
    };

    Ok(TxEip1559 {
        chain_id: params.chain_id,
        nonce: params.nonce,
        gas_limit: params.gas_limit,
        max_fee_per_gas: params.max_fee_per_gas,
        max_priority_fee_per_gas: params.max_priority_fee_per_gas,
        to,
        value: params.value,
        access_list: Default::default(),
        input: Bytes::from(params.input.clone()),
    })
}

/// Parameters for building a legacy (pre-EIP-1559) transaction.
#[derive(Debug, Clone)]
pub struct LegacyTransactionParams {
    /// Target chain ID (EIP-155 replay protection).
    pub chain_id: ChainId,
    /// Sender's current nonce.
    pub nonce: u64,
    /// Recipient address (None for contract creation).
    pub to: Option<Address>,
    /// Value to transfer in wei.
    pub value: U256,
    /// Calldata for the transaction.
    pub input: Vec<u8>,
    /// Gas limit.
    pub gas_limit: u64,
    /// Gas price in wei.
    pub gas_price: u128,
}

impl LegacyTransactionParams {
    /// Validates legacy transaction parameters before building.
    pub fn validate(&self) -> Result<()> {
        if self.chain_id == 0 {
            return Err(UnvaultError::TransactionBuild("chain_id must be non-zero".into()));
        }
        if self.gas_limit == 0 {
            return Err(UnvaultError::TransactionBuild("gas_limit must be non-zero".into()));
        }
        if self.gas_price == 0 {
            return Err(UnvaultError::TransactionBuild("gas_price must be non-zero".into()));
        }
        Ok(())
    }
}

/// Builds an unsigned legacy transaction from the given parameters.
///
/// Used for chains that don't support EIP-1559 (e.g., BSC, Avalanche).
///
/// # Errors
/// - `TransactionBuild` if parameters are invalid.
pub fn build_legacy(params: &LegacyTransactionParams) -> Result<TxLegacy> {
    params.validate()?;

    let to = match params.to {
        Some(addr) => TxKind::Call(addr),
        None => TxKind::Create,
    };

    Ok(TxLegacy {
        chain_id: Some(params.chain_id),
        nonce: params.nonce,
        gas_limit: params.gas_limit,
        gas_price: params.gas_price,
        to,
        value: params.value,
        input: Bytes::from(params.input.clone()),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_params() -> TransactionParams {
        TransactionParams {
            chain_id: 1,
            nonce: 0,
            to: Some(Address::ZERO),
            value: U256::from(1_000_000_000_000_000_000u128), // 1 ETH
            input: vec![],
            gas_limit: 21_000,
            max_fee_per_gas: 30_000_000_000,         // 30 Gwei
            max_priority_fee_per_gas: 1_500_000_000, // 1.5 Gwei
        }
    }

    #[test]
    fn build_eip1559_succeeds() {
        let params = test_params();
        let tx = build_eip1559(&params).unwrap();

        assert_eq!(tx.chain_id, 1);
        assert_eq!(tx.nonce, 0);
        assert_eq!(tx.gas_limit, 21_000);
        assert_eq!(tx.value, U256::from(1_000_000_000_000_000_000u128));
    }

    #[test]
    fn build_eip1559_contract_creation() {
        let mut params = test_params();
        params.to = None;
        params.input = vec![0x60, 0x80, 0x60, 0x40]; // sample bytecode

        let tx = build_eip1559(&params).unwrap();
        assert_eq!(tx.to, TxKind::Create);
        assert!(!tx.input.is_empty());
    }

    #[test]
    fn build_eip1559_zero_chain_id_fails() {
        let mut params = test_params();
        params.chain_id = 0;

        let result = build_eip1559(&params);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::TransactionBuild(_)));
    }

    #[test]
    fn build_eip1559_zero_gas_limit_fails() {
        let mut params = test_params();
        params.gas_limit = 0;

        let result = build_eip1559(&params);
        assert!(result.is_err());
    }

    #[test]
    fn build_eip1559_zero_max_fee_fails() {
        let mut params = test_params();
        params.max_fee_per_gas = 0;

        let result = build_eip1559(&params);
        assert!(result.is_err());
    }

    #[test]
    fn build_eip1559_priority_exceeds_max_fee_fails() {
        let mut params = test_params();
        params.max_priority_fee_per_gas = 50_000_000_000;
        params.max_fee_per_gas = 30_000_000_000;

        let result = build_eip1559(&params);
        assert!(result.is_err());
    }

    #[test]
    fn validate_valid_params() {
        let params = test_params();
        assert!(params.validate().is_ok());
    }

    #[test]
    fn build_eip1559_with_calldata() {
        let mut params = test_params();
        // ERC-20 transfer selector + dummy args
        params.input = vec![0xa9, 0x05, 0x9c, 0xbb];
        params.gas_limit = 65_000;

        let tx = build_eip1559(&params).unwrap();
        assert_eq!(tx.input.len(), 4);
        assert_eq!(tx.gas_limit, 65_000);
    }

    #[test]
    fn build_eip1559_high_nonce() {
        let mut params = test_params();
        params.nonce = u64::MAX;

        let tx = build_eip1559(&params).unwrap();
        assert_eq!(tx.nonce, u64::MAX);
    }

    fn test_legacy_params() -> LegacyTransactionParams {
        LegacyTransactionParams {
            chain_id: 56, // BSC
            nonce: 0,
            to: Some(Address::ZERO),
            value: U256::from(1_000_000_000_000_000_000u128),
            input: vec![],
            gas_limit: 21_000,
            gas_price: 5_000_000_000, // 5 Gwei
        }
    }

    #[test]
    fn build_legacy_succeeds() {
        let params = test_legacy_params();
        let tx = build_legacy(&params).unwrap();

        assert_eq!(tx.chain_id, Some(56));
        assert_eq!(tx.nonce, 0);
        assert_eq!(tx.gas_limit, 21_000);
        assert_eq!(tx.gas_price, 5_000_000_000);
        assert_eq!(tx.value, U256::from(1_000_000_000_000_000_000u128));
    }

    #[test]
    fn build_legacy_zero_chain_id_fails() {
        let mut params = test_legacy_params();
        params.chain_id = 0;

        let result = build_legacy(&params);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::TransactionBuild(_)));
    }

    #[test]
    fn build_legacy_zero_gas_limit_fails() {
        let mut params = test_legacy_params();
        params.gas_limit = 0;

        assert!(build_legacy(&params).is_err());
    }

    #[test]
    fn build_legacy_zero_gas_price_fails() {
        let mut params = test_legacy_params();
        params.gas_price = 0;

        assert!(build_legacy(&params).is_err());
    }

    #[test]
    fn build_legacy_contract_creation() {
        let mut params = test_legacy_params();
        params.to = None;
        params.input = vec![0x60, 0x80];

        let tx = build_legacy(&params).unwrap();
        assert_eq!(tx.to, TxKind::Create);
    }

    #[test]
    fn build_legacy_has_chain_id_for_eip155() {
        let params = test_legacy_params();
        let tx = build_legacy(&params).unwrap();
        // EIP-155: chain_id must be present for replay protection
        assert!(tx.chain_id.is_some());
    }
}
