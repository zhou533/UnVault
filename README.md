# UnVault

Secure, open-source Ethereum HD wallet for iOS and Android.

## Architecture

```
Flutter UI (Riverpod + go_router + freezed + drift)
    ↕ flutter_rust_bridge v2 (Vec<u8>/Uint8List only)
Rust Core (BIP-39/44, Argon2id, AES-256-GCM, alloy)
    ↕ Platform Channel
iOS Keychain / Android Keystore
```

- **Flutter** — UI, state management, routing. Feature-first with domain/data/application/presentation layers.
- **Rust** — ALL cryptography. Mnemonic generation, key derivation, encryption, transaction signing.
- **Native** — Encrypted storage only. Never touches plaintext keys.

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| Frontend | Flutter 3.38+, Riverpod 3.x, go_router, freezed 3.x, drift |
| Core | Rust, alloy, coins-bip32/39, argon2, aes-gcm |
| Bridge | flutter_rust_bridge v2 |
| Storage | iOS Keychain / Android Keystore (sensitive), SQLite/drift (metadata) |

## Project Structure

```
unvault/
├── rust/                    # Rust cryptographic core (132 tests)
│   └── src/
│       ├── api/             # FFI thin wrappers (exposed to Flutter)
│       ├── crypto/          # BIP-39, BIP-44, Argon2id, AES-256-GCM
│       ├── wallet/          # Wallet lifecycle management
│       ├── transaction/     # EIP-1559 tx building & signing
│       └── models/          # Shared types
├── lib/                     # Flutter UI
│   ├── main.dart            # Entry point (ProviderScope + FRB init)
│   ├── app.dart             # MaterialApp.router
│   └── src/
│       ├── features/        # 7 feature modules (wallet, auth, backup, transfer, history, network, settings)
│       ├── core/            # Shared infrastructure (DB, providers, constants, exceptions)
│       ├── routing/         # go_router route tree + named route constants
│       └── localization/    # i18n ARB files (EN + ZH)
├── test/                    # Flutter tests (unit, widget, golden)
├── integration_test/        # E2E tests
├── android/                 # Android platform code
└── ios/                     # iOS platform code
```

## Getting Started

### Prerequisites

- Flutter 3.38+ — `flutter --version`
- Rust 1.75+ — `rustc --version`
- Xcode (iOS) / Android Studio (Android)

### Setup

```bash
# Install Flutter dependencies
flutter pub get

# Run Rust tests
cd rust && cargo test --all-targets && cd ..

# Generate Dart code (drift, Riverpod, freezed)
dart run build_runner build --delete-conflicting-outputs

# Launch app (simulator/emulator must be running)
flutter run
```

## Security Principles

| Principle | Implementation |
|-----------|---------------|
| Signing in Rust only | Private keys never cross FFI boundary |
| Bytes-only FFI | `Vec<u8>`/`Uint8List` for all sensitive data, never `String` |
| Zeroize secrets | All sensitive memory cleared immediately after use |
| CSPRNG only | `OsRng` for all cryptographic randomness — never `thread_rng` |
| Double protection | Argon2id encryption + platform Keychain/Keystore |
| No sensitive logs | Error messages never contain keys, mnemonics, or passwords |

## Development

```bash
# Rust checks
cd rust
cargo fmt --check
cargo clippy --all-targets -- -D warnings
cargo test --all-targets

# Flutter checks
flutter analyze
flutter test --coverage
```

## Conventions

See [CLAUDE.md](CLAUDE.md) for full architecture rules and security constraints.

## License

TBD
