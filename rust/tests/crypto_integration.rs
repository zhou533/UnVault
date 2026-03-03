/// Integration tests that exercise multiple crypto modules together.
mod common;

use secrecy::ExposeSecret;

use unvault_core::crypto::{argon2, encryption, key_derivation, mnemonic};

/// Full mnemonic-to-address pipeline:
/// generate → validate → derive seed → derive account → verify EIP-55 address.
#[test]
fn mnemonic_to_address_pipeline() {
    // Generate a fresh 12-word mnemonic.
    let secret_mnemonic = mnemonic::generate(mnemonic::WordCount::Words12).unwrap();
    let phrase = secret_mnemonic.expose_secret();

    // Validate the generated mnemonic.
    mnemonic::validate(phrase.as_bytes()).unwrap();

    // Derive a BIP-39 seed (no passphrase).
    let seed = mnemonic::derive_seed(phrase.as_bytes(), b"").unwrap();
    assert_eq!(seed.expose_secret().as_bytes().len(), 64);

    // Derive Ethereum account at index 0.
    let account = key_derivation::derive_account(seed.expose_secret().as_bytes(), 0).unwrap();

    // Verify address format (EIP-55 checksummed).
    let addr = format!("{}", account.address);
    assert!(addr.starts_with("0x"));
    assert_eq!(addr.len(), 42);
    assert_eq!(account.key_pair.expose_secret().as_bytes().len(), 32);
}

/// Known BIP-39 test vector: "abandon...about" with passphrase "TREZOR"
/// → derive seed → derive account at index 0 → verify known address.
#[test]
fn known_test_vector_mnemonic_to_address() {
    let seed = mnemonic::derive_seed(common::TEST_MNEMONIC_12, b"TREZOR").unwrap();

    let expected_seed_hex = "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04";
    assert_eq!(hex::encode(seed.expose_secret().as_bytes()), expected_seed_hex);

    let account = key_derivation::derive_account(seed.expose_secret().as_bytes(), 0).unwrap();
    assert_eq!(account.address.to_checksum(None), "0x9c32F71D4DB8Fb9e1A58B0a80dF79935e7256FA6");
}

/// Full encryption round-trip:
/// password → Argon2id → derived key → AES-GCM encrypt mnemonic → decrypt → verify.
#[test]
fn password_encrypt_decrypt_mnemonic() {
    let password = b"test_password_for_integration";
    let salt = common::test_salt();
    let params = common::fast_argon2_params();

    // Derive encryption key from password.
    let derived_key = argon2::derive_key(password, &salt, &params).unwrap();
    let key_bytes = derived_key.expose_secret().as_bytes();
    assert_eq!(key_bytes.len(), 32);

    // Encrypt the test mnemonic.
    let encrypted = encryption::encrypt(key_bytes, common::TEST_MNEMONIC_12).unwrap();

    // Verify ciphertext is different from plaintext.
    assert_ne!(&encrypted, common::TEST_MNEMONIC_12);

    // Decrypt with the same key.
    let decrypted = encryption::decrypt(key_bytes, &encrypted).unwrap();
    assert_eq!(decrypted.as_slice(), common::TEST_MNEMONIC_12);
}

/// Cross-module round-trip:
/// generate mnemonic → encrypt → decrypt → re-derive account → same address.
#[test]
fn generate_encrypt_decrypt_rederive_same_address() {
    // Generate mnemonic.
    let secret_mnemonic = mnemonic::generate(mnemonic::WordCount::Words12).unwrap();
    let phrase_bytes = secret_mnemonic.expose_secret().as_bytes().to_vec();

    // Derive account from the original mnemonic.
    let seed = mnemonic::derive_seed(&phrase_bytes, b"").unwrap();
    let original_account =
        key_derivation::derive_account(seed.expose_secret().as_bytes(), 0).unwrap();

    // Encrypt the mnemonic phrase.
    let password = b"vault_password";
    let salt = argon2::generate_salt();
    let params = common::fast_argon2_params();
    let key = argon2::derive_key(password, &salt, &params).unwrap();
    let encrypted = encryption::encrypt(key.expose_secret().as_bytes(), &phrase_bytes).unwrap();

    // Decrypt the mnemonic phrase.
    let key2 = argon2::derive_key(password, &salt, &params).unwrap();
    let decrypted = encryption::decrypt(key2.expose_secret().as_bytes(), &encrypted).unwrap();

    // Validate and re-derive.
    mnemonic::validate(&decrypted).unwrap();
    let seed2 = mnemonic::derive_seed(&decrypted, b"").unwrap();
    let recovered_account =
        key_derivation::derive_account(seed2.expose_secret().as_bytes(), 0).unwrap();

    // Same address and key.
    assert_eq!(original_account.address, recovered_account.address);
    assert_eq!(
        original_account.key_pair.expose_secret().as_bytes(),
        recovered_account.key_pair.expose_secret().as_bytes()
    );
}

/// Verify that batch derivation matches individual derivation end-to-end.
#[test]
fn batch_derivation_consistency() {
    let seed = common::test_seed_trezor();

    let batch = key_derivation::derive_accounts(&seed, 5).unwrap();

    for (i, batch_account) in batch.iter().enumerate() {
        let individual = key_derivation::derive_account(&seed, i as u32).unwrap();
        assert_eq!(batch_account.address, individual.address);
        assert_eq!(
            batch_account.key_pair.expose_secret().as_bytes(),
            individual.key_pair.expose_secret().as_bytes()
        );
    }
}

/// Decryption with wrong password fails.
#[test]
fn wrong_password_decryption_fails() {
    let salt = common::test_salt();
    let params = common::fast_argon2_params();

    let correct_key = argon2::derive_key(b"correct_password", &salt, &params).unwrap();
    let wrong_key = argon2::derive_key(b"wrong_password", &salt, &params).unwrap();

    let encrypted =
        encryption::encrypt(correct_key.expose_secret().as_bytes(), b"secret data").unwrap();

    let result = encryption::decrypt(wrong_key.expose_secret().as_bytes(), &encrypted);
    assert!(result.is_err());
}
