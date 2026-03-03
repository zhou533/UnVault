# Flutter/Dart Rules

## Sensitive Data Handling

- Sensitive data ONLY as `Uint8List` - NEVER convert to `String` (String is immutable, may be interned by VM)
- Zero-fill `Uint8List` immediately after use (overwrite with zeros)
- Never put private keys or mnemonics in clipboard - addresses only, auto-clear after 60s
- Clear sensitive data from memory ASAP after UI display

## Feature-First Structure

Each `features/*/` module has 4 layers:

| Layer | Responsibility | Dependencies |
|-------|---------------|--------------|
| `domain/` | Freezed immutable models | None (pure data) |
| `data/` | Repository (FRB bridge, DB, network) | domain |
| `application/` | Business logic services | domain, data |
| `presentation/` | Screens, AsyncNotifier controllers, widgets | all above |

Cross-feature shared code goes in `core/` (database, providers, common_widgets, utils).

## State Management (Riverpod)

- Provider declarations at correct scope (global in `core/providers/`, feature-scoped in feature module)
- Widgets never call Repository directly - go through application layer (Service/Notifier)
- Use `AsyncNotifier` for async operations (RPC, crypto)
- Use `ProviderScope` overrides for testing

## Widget Guidelines

- No `build()` methods over 200 lines - decompose
- Dispose controllers, subscriptions, and animation controllers in `dispose()`
- Strings through `localization/` ARB files - no hardcoded user-facing text
- Colors through `Theme` - no hardcoded color values
- Screens with sensitive content (mnemonic, private key): enable screenshot protection

## Database (drift/SQLite)

- Non-sensitive data ONLY: wallet metadata, public addresses, tx history cache, user preferences
- NEVER store plaintext keys, mnemonics, passwords in SQLite
- Schema version management with explicit migrations in `migrations/`

## Routing (go_router)

- Auth guard: redirect to lock screen if unauthenticated
- Route names as constants in `route_names.dart`
- Deep link support for V2 WalletConnect

## Testing

See `testing-flutter.md` for full standards and structure.

- Run: `flutter test --coverage`
