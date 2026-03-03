use thiserror::Error;

/// Unified error type for all unvault-core operations.
///
/// SECURITY: Error messages must NEVER contain sensitive data
/// (private keys, mnemonics, passwords, derived keys).
#[derive(Debug, Error)]
pub enum UnvaultError {
    // -- Mnemonic errors --
    #[error("invalid mnemonic: {0}")]
    InvalidMnemonic(String),

    #[error("mnemonic generation failed: {0}")]
    MnemonicGeneration(String),

    // -- Key derivation errors --
    #[error("key derivation failed: {0}")]
    KeyDerivation(String),

    #[error("invalid derivation path: {0}")]
    InvalidDerivationPath(String),

    // -- Argon2id errors --
    #[error("argon2id derivation failed: {0}")]
    Argon2Derivation(String),

    #[error("invalid argon2id parameters: {0}")]
    InvalidArgon2Params(String),

    // -- Encryption errors --
    #[error("encryption failed: {0}")]
    Encryption(String),

    #[error("decryption failed: authentication tag mismatch")]
    DecryptionFailed,

    #[error("invalid key length: expected {expected}, got {actual}")]
    InvalidKeyLength { expected: usize, actual: usize },

    // -- Memory errors --
    #[error("memory lock failed: {0}")]
    MemoryLock(String),

    // -- Transaction errors --
    #[error("transaction build failed: {0}")]
    TransactionBuild(String),

    #[error("transaction signing failed: {0}")]
    TransactionSign(String),

    // -- Wallet errors --
    #[error("wallet operation failed: {0}")]
    WalletOperation(String),
}

/// Result type alias for unvault-core operations.
pub type Result<T> = std::result::Result<T, UnvaultError>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn error_display_invalid_mnemonic() {
        let err = UnvaultError::InvalidMnemonic("checksum mismatch".into());
        assert_eq!(err.to_string(), "invalid mnemonic: checksum mismatch");
    }

    #[test]
    fn error_display_mnemonic_generation() {
        let err = UnvaultError::MnemonicGeneration("entropy source unavailable".into());
        assert_eq!(err.to_string(), "mnemonic generation failed: entropy source unavailable");
    }

    #[test]
    fn error_display_key_derivation() {
        let err = UnvaultError::KeyDerivation("invalid seed length".into());
        assert_eq!(err.to_string(), "key derivation failed: invalid seed length");
    }

    #[test]
    fn error_display_invalid_derivation_path() {
        let err = UnvaultError::InvalidDerivationPath("missing hardened marker".into());
        assert_eq!(err.to_string(), "invalid derivation path: missing hardened marker");
    }

    #[test]
    fn error_display_argon2_derivation() {
        let err = UnvaultError::Argon2Derivation("output too short".into());
        assert_eq!(err.to_string(), "argon2id derivation failed: output too short");
    }

    #[test]
    fn error_display_invalid_argon2_params() {
        let err = UnvaultError::InvalidArgon2Params("memory below safety floor".into());
        assert_eq!(err.to_string(), "invalid argon2id parameters: memory below safety floor");
    }

    #[test]
    fn error_display_encryption() {
        let err = UnvaultError::Encryption("cipher initialization failed".into());
        assert_eq!(err.to_string(), "encryption failed: cipher initialization failed");
    }

    #[test]
    fn error_display_decryption_failed() {
        let err = UnvaultError::DecryptionFailed;
        assert_eq!(err.to_string(), "decryption failed: authentication tag mismatch");
    }

    #[test]
    fn error_display_invalid_key_length() {
        let err = UnvaultError::InvalidKeyLength { expected: 32, actual: 16 };
        assert_eq!(err.to_string(), "invalid key length: expected 32, got 16");
    }

    #[test]
    fn error_display_memory_lock() {
        let err = UnvaultError::MemoryLock("operation not permitted".into());
        assert_eq!(err.to_string(), "memory lock failed: operation not permitted");
    }

    #[test]
    fn error_display_transaction_build() {
        let err = UnvaultError::TransactionBuild("chain_id must be non-zero".into());
        assert_eq!(err.to_string(), "transaction build failed: chain_id must be non-zero");
    }

    #[test]
    fn error_display_transaction_sign() {
        let err = UnvaultError::TransactionSign("invalid private key".into());
        assert_eq!(err.to_string(), "transaction signing failed: invalid private key");
    }

    #[test]
    fn error_display_wallet_operation() {
        let err = UnvaultError::WalletOperation("wallet not found".into());
        assert_eq!(err.to_string(), "wallet operation failed: wallet not found");
    }

    #[test]
    fn error_is_send_and_sync() {
        fn assert_send_sync<T: Send + Sync>() {}
        assert_send_sync::<UnvaultError>();
    }

    #[test]
    fn result_type_alias_works() {
        let ok: Result<u32> = Ok(42);
        assert!(ok.is_ok());

        let err: Result<u32> = Err(UnvaultError::DecryptionFailed);
        assert!(err.is_err());
    }
}
