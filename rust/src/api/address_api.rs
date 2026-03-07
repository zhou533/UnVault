//! FFI API for Ethereum address utilities.
//!
//! Provides EIP-55 checksum validation and formatting.

use alloy_primitives::Address;

use crate::error::{Result, UnvaultError};

/// Validates whether an address string has a correct EIP-55 mixed-case checksum.
///
/// Returns `true` if the address has valid EIP-55 checksum casing,
/// `false` if the address is valid hex but has incorrect casing.
///
/// # Errors
/// - `InvalidAddress` if the string is not a valid 40-hex-char address.
pub fn validate_address_checksum(address: String) -> Result<bool> {
    // Parse to validate it's a proper hex address
    let parsed: Address =
        address.parse().map_err(|e| UnvaultError::InvalidAddress(format!("{e}")))?;

    // Compare original with EIP-55 checksummed version
    let checksummed = parsed.to_checksum(None);
    Ok(address == checksummed)
}

/// Converts a hex address string to EIP-55 checksummed format.
///
/// Accepts addresses with or without `0x` prefix, any casing.
///
/// # Errors
/// - `InvalidAddress` if the string is not a valid 40-hex-char address.
pub fn to_checksum_address(address: String) -> Result<String> {
    let parsed: Address =
        address.parse().map_err(|e| UnvaultError::InvalidAddress(format!("{e}")))?;

    Ok(parsed.to_checksum(None))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validate_correct_checksum_returns_true() {
        // EIP-55 checksummed address
        let result =
            validate_address_checksum("0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed".into()).unwrap();
        assert!(result);
    }

    #[test]
    fn validate_wrong_checksum_returns_false() {
        // All lowercase — valid hex, but not checksummed
        let result =
            validate_address_checksum("0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed".into()).unwrap();
        assert!(!result);
    }

    #[test]
    fn validate_all_uppercase_returns_false() {
        let result =
            validate_address_checksum("0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAED".into()).unwrap();
        assert!(!result);
    }

    #[test]
    fn validate_invalid_hex_returns_error() {
        let result = validate_address_checksum("0xZZZZ".into());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidAddress(_)));
    }

    #[test]
    fn validate_empty_string_returns_error() {
        let result = validate_address_checksum("".into());
        assert!(result.is_err());
    }

    #[test]
    fn to_checksum_from_lowercase() {
        let checksummed =
            to_checksum_address("0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed".into()).unwrap();
        assert_eq!(checksummed, "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");
    }

    #[test]
    fn to_checksum_from_uppercase() {
        let checksummed =
            to_checksum_address("0x5AAEB6053F3E94C9B9A09F33669435E7EF1BEAED".into()).unwrap();
        assert_eq!(checksummed, "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");
    }

    #[test]
    fn to_checksum_without_prefix() {
        let checksummed =
            to_checksum_address("5aaeb6053f3e94c9b9a09f33669435e7ef1beaed".into()).unwrap();
        assert_eq!(checksummed, "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed");
    }

    #[test]
    fn to_checksum_zero_address() {
        let checksummed =
            to_checksum_address("0x0000000000000000000000000000000000000000".into()).unwrap();
        assert_eq!(checksummed, "0x0000000000000000000000000000000000000000");
    }

    #[test]
    fn to_checksum_invalid_address_returns_error() {
        let result = to_checksum_address("not_an_address".into());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidAddress(_)));
    }

    #[test]
    fn to_checksum_already_checksummed_is_idempotent() {
        let addr = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";
        let checksummed = to_checksum_address(addr.into()).unwrap();
        assert_eq!(checksummed, addr);
    }
}
