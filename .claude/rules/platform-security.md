---
paths:
  - "android/**"
  - "ios/**"
  - "lib/src/features/auth/**"
description: Platform-specific security and authentication rules
---

# Platform Security Rules

## Keychain / Keystore Storage

Keys stored per wallet:
- `wallet_{id}_mnemonic`: nonce + ciphertext + tag (Argon2id + AES-GCM encrypted)
- `wallet_{id}_salt`: 16 bytes random (Argon2id salt)
- `wallet_{id}_argon2_params`: calibrated memory, iterations, parallelism
- `wallet_{id}_auth_key`: biometric-protected encryption key

## Biometric Authentication

- Biometric authorizes reading encrypted key from Keychain/Keystore - does NOT replace password
- First unlock and sensitive ops (export mnemonic, large transfer): always require password
- **iOS**: `kSecAccessControlBiometryCurrentSet` - invalidate on biometric change
- **Android**: `setUserAuthenticationRequired(true)` + BiometricPrompt
- Biometric bypass must NOT directly expose decryption key

## App Protection

- Screenshot/recording: disabled on mnemonic/key display screens
  - Android: `FLAG_SECURE`
  - iOS: monitor `UIScreen.capturedDidChangeNotification`, mask content
- Background: show privacy mask immediately (prevent task switcher leaks)
- Auto-lock: configurable (immediate / 30s default / 1min / 5min)
- Clipboard: address copy auto-clears after 60s; NEVER clipboard keys/mnemonics

## Brute Force Protection

- Password failure: exponential backoff (1s, 2s, 4s, 8s...)
- 10 consecutive failures: lock app for 30+ minutes
- Password minimum: 8 characters, strength indicator in UI

## Build Security

- Flutter: `--obfuscate` + `--split-debug-info`
- Rust: release profile with strip, LTO enabled
- Root/jailbreak: detect and warn user (don't block usage)
