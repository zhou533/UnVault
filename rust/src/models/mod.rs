#![allow(dead_code)]

/// Re-export Ethereum address type (EIP-55 checksummed).
pub use alloy_primitives::Address;

/// Chain configuration for multi-chain support (Phase 2).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ChainConfig {
    /// EIP-155 chain ID.
    pub chain_id: u64,
    /// Human-readable chain name.
    pub name: String,
}

impl ChainConfig {
    /// Ethereum Mainnet.
    pub fn mainnet() -> Self {
        Self { chain_id: 1, name: "Ethereum Mainnet".into() }
    }

    /// Sepolia Testnet.
    pub fn sepolia() -> Self {
        Self { chain_id: 11155111, name: "Sepolia".into() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn chain_config_mainnet() {
        let config = ChainConfig::mainnet();
        assert_eq!(config.chain_id, 1);
        assert_eq!(config.name, "Ethereum Mainnet");
    }

    #[test]
    fn chain_config_sepolia() {
        let config = ChainConfig::sepolia();
        assert_eq!(config.chain_id, 11155111);
    }

    #[test]
    fn address_re_export_works() {
        let addr = Address::ZERO;
        assert_eq!(format!("{addr}"), "0x0000000000000000000000000000000000000000");
    }
}
