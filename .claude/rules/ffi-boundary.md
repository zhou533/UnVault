---
paths:
  - "rust/src/api/**"
  - "lib/src/rust/**"
  - "flutter_rust_bridge.yaml"
description: FFI bridge boundary rules
---

# FFI Boundary Rules

## Data Crossing the Bridge

- Sensitive data: `Vec<u8>` (Rust) / `Uint8List` (Dart) ONLY
- NEVER pass mnemonics, keys, or passwords as `String` across FFI
- Non-sensitive data (addresses, tx hashes, network config): String is acceptable

## API Layer (`rust/src/api/`)

- Thin wrappers only: parameter type conversion + error code mapping
- No business logic - delegate to domain modules (crypto/, wallet/, transaction/)
- Every API function must map domain errors to FFI-safe error codes
- Document each exposed function with expected input/output formats

## Auto-Generated Code

- `frb_generated.rs`, `frb_generated.dart`: NEVER hand-edit
- After API changes: run `flutter_rust_bridge_codegen generate`
- CI verifies generated code is up-to-date via `git diff --exit-code`

## Error Propagation

- Rust domain errors -> thiserror types -> FFI error codes at api/ layer
- Dart side catches FFI errors and maps to user-facing messages
- Error messages crossing FFI must be sanitized (no sensitive data)
