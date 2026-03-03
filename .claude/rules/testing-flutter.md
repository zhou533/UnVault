---
paths:
  - "test/**"
  - "integration_test/**"
description: Flutter testing standards
---

# Flutter Testing Standards

## Unit Tests (`test/unit/`)

- Mirror `lib/src/` directory structure
- Mock Rust layer with `mocktail`: `MockRustLibApi extends Mock implements RustLibApi`
- Test Service/Repository logic independently from UI
- Inject mocks via `RustLib.init(api: mockRustApi)`

## Widget Tests (`test/widget/`)

- Use `pumpApp` helper from `test/helpers/pump_app.dart`:
  ```dart
  await tester.pumpApp(MyWidget(), overrides: [provider.overrideWith(...)]);
  ```
- Test rendering, user interaction, and state transitions
- Override providers with mocks via `ProviderScope`

## Golden Tests (`test/golden/`)

- Visual regression tests for key UI components
- Baselines stored in `test/goldens/ci/` (platform-independent)
- Update: `flutter test --update-goldens`
- Run in CI to catch unintended visual changes

## Integration Tests (`integration_test/`)

- Run on real device/simulator only
- Initialize real Rust library: `await RustLib.init()`
- Key flows:
  - FFI bridge verification (mnemonic generation, encrypt/decrypt roundtrip)
  - Full wallet creation flow (create -> password -> backup -> verify)
- Run: `flutter test integration_test/`

## Test Data

- Fixtures in `test/fixtures/` (JSON test data)
- Mocks in `test/mocks/` with barrel file `mocks.dart`
- Never use real private keys or mnemonics in test fixtures
