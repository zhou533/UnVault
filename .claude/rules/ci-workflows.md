---
paths:
  - ".github/**"
description: CI/CD workflow standards
---

# CI/CD Standards

## Workflow Files

| File | Purpose | Trigger |
|------|---------|---------|
| `rust.yml` | fmt, clippy, test, coverage | PR + push main (rust/ changes) |
| `flutter.yml` | analyze, test, golden, codegen check | PR + push main |
| `build.yml` | Android APK + iOS build | push main + tags (v*) |
| `audit.yml` | cargo deny, flutter pub outdated | Daily + dependency file changes |

## Blocking Checks (must pass for merge)

- Rust: fmt, clippy (-D warnings), test
- Flutter: format, analyze (--fatal-infos), test, golden tests
- Generated code consistency: codegen + `git diff --exit-code`

## Non-Blocking (report only)

- Coverage reports (Codecov)
- Build artifacts

## Build Requirements

- Android: `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
- iOS: `flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/debug-info`
- Rust targets: `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`, `aarch64-apple-ios`

## Caching

- Rust: `Swatinem/rust-cache@v2` with `workspaces: rust`
- Flutter: `subosito/flutter-action@v2` with `cache: true`
