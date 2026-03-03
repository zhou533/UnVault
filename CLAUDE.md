# UnVault - Ethereum HD Wallet

## Architecture

Flutter UI + Rust cryptography core, bridged via flutter_rust_bridge v2 (FFI).

```
Flutter UI (Riverpod + go_router + freezed + drift)
    ↕ flutter_rust_bridge v2 (Vec<u8>/Uint8List only)
Rust Core (BIP-39/44, Argon2id, AES-256-GCM, alloy)
    ↕ Platform Channel
iOS Keychain / Android Keystore (encrypted storage only)
```

- **Rust** (`rust/`): ALL cryptography. Mnemonic, key derivation, encryption, transaction signing.
- **Flutter** (`lib/`): UI, state, routing. Feature-first with `domain/data/application/presentation` layers.
- **Native**: Store encrypted bytes only. Never touch plaintext.

## Security Golden Rules

These apply everywhere, always, no exceptions:

1. **No sensitive data in logs** - private keys, mnemonics, passwords, derived keys
2. **FFI boundary: bytes only** - `Vec<u8>`/`Uint8List`, NEVER String for sensitive data
3. **Crypto randomness: OsRng** - NEVER `thread_rng` or non-CSPRNG
4. **Zeroize all secrets** - every sensitive type must `Zeroize + ZeroizeOnDrop`
5. **Dart: Uint8List only** - NEVER convert sensitive bytes to String (immutable, may intern)
6. **Signing in Rust only** - signed raw tx returned to Dart, never private key

## Commit Convention

Conventional Commits: `<type>(<scope>): <description>`

| Type | Use |
|------|-----|
| `feat` | New feature |
| `fix` | Bug fix |
| `security` | Security fix (highest priority review) |
| `refactor` | No behavior change |
| `test` | Tests only |
| `docs` / `ci` / `chore` | Non-code |

Scope examples: `feat(wallet):`, `fix(crypto):`, `security(encryption):`

## PR Requirements

- Title: Conventional Commits format
- All CI checks must pass before merge
- Squash merge to main (linear history)
- Security-scoped changes require additional security checklist (see `.claude/rules/pr-checklist.md`)

## Tech Stack Reference

| Module | Choice |
|--------|--------|
| Wallet type | HD (BIP-39 / BIP-44) |
| Frontend | Flutter + Riverpod + go_router + freezed |
| Core | Rust + flutter_rust_bridge v2 + alloy |
| Database | drift (SQLite) - non-sensitive data only |
| Key derivation | Argon2id (password → key) |
| Encryption | AES-256-GCM |
| Secure storage | iOS Keychain / Android Keystore |
| Error handling | thiserror (Rust) + unified FFI error codes |

## Directory Conventions

- `rust/src/api/`: FRB-exposed thin wrappers only (param conversion + error mapping)
- `rust/src/crypto|wallet|transaction/`: Domain logic modules
- `lib/src/features/*/`: Feature modules with 4-layer structure
- `lib/src/core/`: Shared cross-feature code
- Auto-generated files: commit to VCS but never hand-edit
