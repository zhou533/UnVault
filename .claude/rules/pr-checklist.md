---
paths:
  - ".github/PULL_REQUEST_TEMPLATE.md"
description: PR creation checklist and review standards
---

# PR Checklist & Review Standards

## PR Format

- **Title**: Conventional Commits format (`feat(wallet): add multi-account support`)
- **Description**: What changed, why, how to test
- **Merge strategy**: Squash merge to main

## Required Checks (all PRs)

- [ ] `cargo test --all-features` passes
- [ ] `flutter test` passes
- [ ] `cargo clippy -- -D warnings` clean
- [ ] `cargo fmt --check` clean
- [ ] `flutter analyze --fatal-infos` clean
- [ ] `dart format --set-exit-if-changed` clean
- [ ] New code has corresponding tests
- [ ] Auto-generated code is up-to-date (`flutter_rust_bridge_codegen generate`)

## Security Checklist (when touching crypto/keys/sensitive data)

- [ ] All Security Golden Rules verified (see root `CLAUDE.md`)
- [ ] Dart side: `Uint8List` zero-filled after use

## Review Focus Areas

### Rust (see `rust/CLAUDE.md`)
- Visibility: minimal `pub` exposure
- Dependency: audit new crates

### Flutter (see `lib/CLAUDE.md`)
- State: providers at correct scope, no direct repo access from widgets
- Hardcoding: strings in localization, colors in theme
