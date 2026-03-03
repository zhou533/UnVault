#![allow(dead_code)]

use argon2::{Algorithm, Argon2, Params, Version};
use rand::rngs::OsRng;
use rand::RngCore;
use secrecy::SecretBox;
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::error::{Result, UnvaultError};

/// Output length for the derived key (256-bit / 32 bytes).
const OUTPUT_LENGTH: usize = 32;

/// Salt length in bytes.
pub(crate) const SALT_LENGTH: usize = 16;

/// Safety floor: minimum memory in KiB (32 MB).
const MIN_MEMORY_KIB: u32 = 32 * 1024;

/// Safety floor: minimum iterations.
const MIN_ITERATIONS: u32 = 2;

/// Default starting memory for calibration (64 MB).
const DEFAULT_MEMORY_KIB: u32 = 64 * 1024;

/// Default starting iterations for calibration.
const DEFAULT_ITERATIONS: u32 = 3;

/// Default parallelism.
const DEFAULT_PARALLELISM: u32 = 2;

/// Argon2id parameters that are stored alongside the salt for later decryption.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Argon2Params {
    /// Memory cost in KiB.
    pub memory_kib: u32,
    /// Number of iterations (time cost).
    pub iterations: u32,
    /// Degree of parallelism.
    pub parallelism: u32,
}

impl Argon2Params {
    /// Validates parameters against the safety floor.
    ///
    /// # Errors
    /// - `InvalidArgon2Params` if memory or iterations are below the safety floor.
    pub fn validate(&self) -> Result<()> {
        if self.memory_kib < MIN_MEMORY_KIB {
            return Err(UnvaultError::InvalidArgon2Params(format!(
                "memory {}KiB below safety floor {}KiB",
                self.memory_kib, MIN_MEMORY_KIB
            )));
        }
        if self.iterations < MIN_ITERATIONS {
            return Err(UnvaultError::InvalidArgon2Params(format!(
                "iterations {} below safety floor {}",
                self.iterations, MIN_ITERATIONS
            )));
        }
        if self.parallelism == 0 {
            return Err(UnvaultError::InvalidArgon2Params("parallelism must be at least 1".into()));
        }
        Ok(())
    }

    /// Returns the default high-end parameters (starting point for calibration).
    pub(crate) fn default_high() -> Self {
        Self {
            memory_kib: DEFAULT_MEMORY_KIB,
            iterations: DEFAULT_ITERATIONS,
            parallelism: DEFAULT_PARALLELISM,
        }
    }

    /// Returns the safety floor parameters (minimum acceptable).
    pub(crate) fn safety_floor() -> Self {
        Self { memory_kib: MIN_MEMORY_KIB, iterations: MIN_ITERATIONS, parallelism: 1 }
    }
}

/// A 32-byte derived encryption key.
///
/// No `Debug` or `Display` implementation.
/// Implements `Zeroize + ZeroizeOnDrop`.
#[derive(Zeroize, ZeroizeOnDrop)]
pub struct DerivedKey(pub(crate) [u8; OUTPUT_LENGTH]);

impl DerivedKey {
    /// Access the key as a byte slice.
    pub fn as_bytes(&self) -> &[u8] {
        &self.0
    }
}

/// A derived key wrapped in `SecretBox` for protection.
pub type SecretDerivedKey = SecretBox<DerivedKey>;

/// Generates a random 16-byte salt using `OsRng` (CSPRNG).
pub fn generate_salt() -> [u8; SALT_LENGTH] {
    let mut salt = [0u8; SALT_LENGTH];
    OsRng.fill_bytes(&mut salt);
    salt
}

/// Derives a 32-byte encryption key from a password and salt using Argon2id.
///
/// # Errors
/// - `InvalidArgon2Params` if params are below the safety floor.
/// - `Argon2Derivation` if the underlying Argon2id operation fails.
pub fn derive_key(
    password: &[u8],
    salt: &[u8; SALT_LENGTH],
    params: &Argon2Params,
) -> Result<SecretDerivedKey> {
    params.validate()?;

    let argon2_params =
        Params::new(params.memory_kib, params.iterations, params.parallelism, Some(OUTPUT_LENGTH))
            .map_err(|e| UnvaultError::Argon2Derivation(e.to_string()))?;

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, argon2_params);

    let mut output = [0u8; OUTPUT_LENGTH];
    argon2
        .hash_password_into(password, salt, &mut output)
        .map_err(|e| UnvaultError::Argon2Derivation(e.to_string()))?;

    Ok(SecretBox::new(Box::new(DerivedKey(output))))
}

/// Calibrates Argon2id parameters for the current device.
///
/// Starts from high parameters and decreases until the derivation latency
/// falls within `target_ms` range (min, max). Never goes below the safety floor.
///
/// # Errors
/// - `Argon2Derivation` if calibration fails.
pub fn calibrate(target_ms: (u64, u64)) -> Result<Argon2Params> {
    let (min_ms, max_ms) = target_ms;
    let test_password = b"calibration_test_password";
    let test_salt = generate_salt();

    let mut params = Argon2Params::default_high();

    // Try up to 10 iterations to converge.
    for _ in 0..10 {
        let start = std::time::Instant::now();
        let _ = derive_key_unchecked(test_password, &test_salt, &params)?;
        let elapsed_ms = start.elapsed().as_millis() as u64;

        if elapsed_ms >= min_ms && elapsed_ms <= max_ms {
            return Ok(params);
        }

        if elapsed_ms > max_ms {
            // Too slow — reduce memory first, then iterations.
            let new_memory = params.memory_kib * 3 / 4; // Reduce by 25%.
            if new_memory >= MIN_MEMORY_KIB {
                params.memory_kib = new_memory;
            } else {
                params.memory_kib = MIN_MEMORY_KIB;
                // Memory at floor, try reducing iterations.
                if params.iterations > MIN_ITERATIONS {
                    params.iterations -= 1;
                } else {
                    // Already at safety floor — return floor params.
                    return Ok(Argon2Params::safety_floor());
                }
            }
        } else {
            // Too fast — increase iterations.
            params.iterations += 1;
        }
    }

    // Didn't converge — ensure we're at least at the safety floor.
    params.validate()?;
    Ok(params)
}

/// Internal: derives key without checking params against safety floor.
/// Used for calibration where we control the params ourselves.
fn derive_key_unchecked(
    password: &[u8],
    salt: &[u8; SALT_LENGTH],
    params: &Argon2Params,
) -> Result<SecretDerivedKey> {
    let argon2_params =
        Params::new(params.memory_kib, params.iterations, params.parallelism, Some(OUTPUT_LENGTH))
            .map_err(|e| UnvaultError::Argon2Derivation(e.to_string()))?;

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, argon2_params);

    let mut output = [0u8; OUTPUT_LENGTH];
    argon2
        .hash_password_into(password, salt, &mut output)
        .map_err(|e| UnvaultError::Argon2Derivation(e.to_string()))?;

    Ok(SecretBox::new(Box::new(DerivedKey(output))))
}

#[cfg(test)]
mod tests {
    use secrecy::ExposeSecret;

    use super::*;

    /// Fast params at the safety floor for testing.
    fn test_params() -> Argon2Params {
        Argon2Params { memory_kib: MIN_MEMORY_KIB, iterations: MIN_ITERATIONS, parallelism: 1 }
    }

    fn test_salt() -> [u8; SALT_LENGTH] {
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
    }

    #[test]
    fn derive_key_returns_32_bytes() {
        let key = derive_key(b"test_password", &test_salt(), &test_params()).unwrap();
        assert_eq!(key.expose_secret().as_bytes().len(), 32);
    }

    #[test]
    fn derive_key_deterministic() {
        let salt = test_salt();
        let params = test_params();

        let key1 = derive_key(b"same_password", &salt, &params).unwrap();
        let key2 = derive_key(b"same_password", &salt, &params).unwrap();

        assert_eq!(key1.expose_secret().as_bytes(), key2.expose_secret().as_bytes());
    }

    #[test]
    fn derive_key_different_salt_produces_different_key() {
        let params = test_params();
        let salt1 = [1u8; SALT_LENGTH];
        let salt2 = [2u8; SALT_LENGTH];

        let key1 = derive_key(b"password", &salt1, &params).unwrap();
        let key2 = derive_key(b"password", &salt2, &params).unwrap();

        assert_ne!(key1.expose_secret().as_bytes(), key2.expose_secret().as_bytes());
    }

    #[test]
    fn derive_key_different_password_produces_different_key() {
        let salt = test_salt();
        let params = test_params();

        let key1 = derive_key(b"password_one", &salt, &params).unwrap();
        let key2 = derive_key(b"password_two", &salt, &params).unwrap();

        assert_ne!(key1.expose_secret().as_bytes(), key2.expose_secret().as_bytes());
    }

    #[test]
    fn validate_params_at_floor() {
        let params = Argon2Params::safety_floor();
        assert!(params.validate().is_ok());
    }

    #[test]
    fn validate_params_above_floor() {
        let params = Argon2Params::default_high();
        assert!(params.validate().is_ok());
    }

    #[test]
    fn validate_params_memory_below_floor() {
        let params = Argon2Params {
            memory_kib: 1024, // 1 MB, well below 32 MB floor.
            iterations: 2,
            parallelism: 1,
        };
        let result = params.validate();
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidArgon2Params(_)));
    }

    #[test]
    fn validate_params_iterations_below_floor() {
        let params = Argon2Params { memory_kib: MIN_MEMORY_KIB, iterations: 1, parallelism: 1 };
        let result = params.validate();
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UnvaultError::InvalidArgon2Params(_)));
    }

    #[test]
    fn validate_params_zero_parallelism() {
        let params =
            Argon2Params { memory_kib: MIN_MEMORY_KIB, iterations: MIN_ITERATIONS, parallelism: 0 };
        let result = params.validate();
        assert!(result.is_err());
    }

    #[test]
    fn derive_key_rejects_below_floor_params() {
        let salt = test_salt();
        let params = Argon2Params { memory_kib: 1024, iterations: 1, parallelism: 1 };
        let result = derive_key(b"password", &salt, &params);
        assert!(result.is_err());
    }

    #[test]
    fn generate_salt_returns_16_bytes() {
        let salt = generate_salt();
        assert_eq!(salt.len(), SALT_LENGTH);
    }

    #[test]
    fn generate_salt_produces_different_values() {
        let s1 = generate_salt();
        let s2 = generate_salt();
        assert_ne!(s1, s2);
    }

    #[test]
    fn calibrate_respects_safety_floor() {
        // Even with an impossibly tight target, params should be at least at safety floor.
        let params = calibrate((1, 50)).unwrap();
        assert!(params.memory_kib >= MIN_MEMORY_KIB);
        assert!(params.iterations >= MIN_ITERATIONS);
        assert!(params.parallelism >= 1);
    }

    #[test]
    fn calibrate_returns_valid_params() {
        // Use a wide target range to ensure convergence.
        let params = calibrate((100, 10_000)).unwrap();
        assert!(params.validate().is_ok());
    }

    mod proptest_argon2 {
        use super::*;
        use proptest::prelude::*;

        proptest! {
            #[test]
            fn deterministic_derivation(password in ".{8,64}") {
                let salt = [0u8; SALT_LENGTH];
                let params = Argon2Params {
                    memory_kib: MIN_MEMORY_KIB,
                    iterations: MIN_ITERATIONS,
                    parallelism: 1,
                };
                let key1 = derive_key(password.as_bytes(), &salt, &params).unwrap();
                let key2 = derive_key(password.as_bytes(), &salt, &params).unwrap();
                prop_assert_eq!(
                    key1.expose_secret().as_bytes(),
                    key2.expose_secret().as_bytes()
                );
            }
        }
    }
}
