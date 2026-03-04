# Core Wallet MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Wire flutter_rust_bridge v2, implement auth + wallet create/import + backup — the complete first user story: open app → set password → create wallet → back up mnemonic → unlock.

**Architecture:** Rust core is 100% complete (132 tests). Flutter scaffold is 100% complete (all screens are stubs). This plan connects them via FRB v2 codegen, then implements the 4 features needed for a working wallet MVP in 4-layer (domain/data/application/presentation) order.

**Tech Stack:** Flutter 3.38, Dart 3.10, flutter_rust_bridge v2.7, Riverpod 3, go_router 14, drift 2, flutter_secure_storage 9, local_auth 2, freezed 3, mocktail

---

## Current State Snapshot

- `rust/src/api/` — 3 FFI API files (crypto_api, wallet_api, transaction_api) with full implementations and tests. NOT yet annotated with FRB macros. NOT yet connected to Flutter.
- `lib/` — full scaffold. Routing, DB tables, providers skeleton, 13 screen stubs. **No Rust bridge generated yet.**
- `flutter_rust_bridge.yaml` — does NOT exist yet.
- `lib/src/rust/` — does NOT exist yet (FRB codegen target directory).

---

## Task 1: FRB v2 Codegen Setup

**Files:**
- Create: `flutter_rust_bridge.yaml`
- Modify: `rust/src/api/crypto_api.rs`
- Modify: `rust/src/api/wallet_api.rs`
- Modify: `rust/src/api/transaction_api.rs`
- Modify: `rust/Cargo.toml` (enable `ffi` feature)
- Modify: `lib/main.dart`
- Generated (do not hand-edit): `rust/src/frb_generated.rs`, `lib/src/rust/frb_generated.dart`, `lib/src/rust/api/*.dart`

**Step 1: Add FRB v2 macros to crypto_api.rs**

Add `#[flutter_rust_bridge::frb(sync)]` to fast functions, leave slow Argon2 functions without (they become async automatically):

```rust
// In rust/src/api/crypto_api.rs
// Remove: #![allow(dead_code)]
// Add to fast (sync) functions:
#[flutter_rust_bridge::frb(sync)]
pub fn generate_mnemonic(word_count: u8) -> Result<Vec<u8>> { ... }

#[flutter_rust_bridge::frb(sync)]
pub fn validate_mnemonic(phrase_bytes: Vec<u8>) -> Result<bool> { ... }

#[flutter_rust_bridge::frb(sync)]
pub fn generate_salt() -> Vec<u8> { ... }

#[flutter_rust_bridge::frb(sync)]
pub fn encrypt(key: Vec<u8>, plaintext: Vec<u8>) -> Result<Vec<u8>> { ... }

#[flutter_rust_bridge::frb(sync)]
pub fn decrypt(key: Vec<u8>, ciphertext: Vec<u8>) -> Result<Vec<u8>> { ... }

// Async (no annotation): derive_seed, derive_key, calibrate_argon2
```

**Step 2: Add FRB v2 macros to wallet_api.rs**

```rust
// Remove: #![allow(dead_code)]
// Async (slow Argon2, no annotation): create_wallet, import_wallet, decrypt_mnemonic
// Fast (sync): derive_accounts
#[flutter_rust_bridge::frb(sync)]
pub fn derive_accounts(phrase_bytes: Vec<u8>, count: u32) -> Result<Vec<String>> { ... }
```

Also annotate the response structs so FRB can generate Dart types:
```rust
#[flutter_rust_bridge::frb]
pub struct WalletCreationResponse { ... }

#[flutter_rust_bridge::frb]
pub struct WalletImportResponse { ... }

#[flutter_rust_bridge::frb]
pub struct SignTransactionResponse { ... }
```

**Step 3: Add FRB v2 macros to transaction_api.rs**

```rust
// Remove: #![allow(dead_code)]
// Async (signing, no annotation): sign_transaction
```

**Step 4: Enable `ffi` feature in Cargo.toml**

In `rust/Cargo.toml`, change:
```toml
[features]
default = []
ffi = ["flutter_rust_bridge"]
```
to:
```toml
[features]
default = ["ffi"]
ffi = ["flutter_rust_bridge"]
```

**Step 5: Create flutter_rust_bridge.yaml**

```yaml
# flutter_rust_bridge.yaml
rust_input:
  - rust/src/api/crypto_api.rs
  - rust/src/api/wallet_api.rs
  - rust/src/api/transaction_api.rs
dart_output: lib/src/rust
rust_root: rust
```

**Step 6: Run FRB codegen**

```bash
cd /Users/cyber/restox/UnVault
flutter_rust_bridge_codegen generate
```

Expected output: generates `lib/src/rust/frb_generated.dart`, `lib/src/rust/api/crypto_api.dart`, `lib/src/rust/api/wallet_api.dart`, `lib/src/rust/api/transaction_api.dart`, and `rust/src/frb_generated.rs`.

**Step 7: Wire RustLib.init() in main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/rust/frb_generated.dart';
import 'package:unvault/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const ProviderScope(child: UnVaultApp()));
}
```

**Step 8: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues found.

**Step 9: Commit**

```bash
git add flutter_rust_bridge.yaml rust/src/ lib/src/rust/ lib/main.dart rust/Cargo.toml
git commit -m "feat(bridge): add FRB v2 codegen - wire Flutter ↔ Rust FFI"
```

---

## Task 2: Secure Storage Service

Thin wrapper over `flutter_secure_storage` that stores/reads wallet credentials by key. This is the only place in Dart that touches encrypted bytes from Rust.

**Files:**
- Create: `lib/src/core/services/secure_storage_service.dart`
- Create: `test/unit/core/services/secure_storage_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/unit/core/services/secure_storage_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService sut;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    sut = SecureStorageService(storage: mockStorage);
  });

  group('storeWalletCredentials', () {
    test('writes all fields under namespaced keys', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await sut.storeWalletCredentials(
        walletId: 1,
        encryptedMnemonic: Uint8List.fromList([1, 2, 3]),
        salt: Uint8List.fromList([4, 5, 6]),
        argon2MemoryKib: 32768,
        argon2Iterations: 2,
        argon2Parallelism: 1,
      );

      verify(() => mockStorage.write(
        key: 'wallet_1_encrypted_mnemonic',
        value: any(named: 'value'),
      )).called(1);
    });
  });

  group('readWalletCredentials', () {
    test('returns null when wallet not found', () async {
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      final result = await sut.readWalletCredentials(walletId: 999);

      expect(result, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/core/services/secure_storage_service_test.dart -v
```
Expected: FAIL with import error.

**Step 3: Implement SecureStorageService**

```dart
// lib/src/core/services/secure_storage_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive wallet data in the platform secure keychain/keystore.
/// Keys are namespaced by wallet ID to support multiple wallets.
/// All binary data is base64-encoded for storage.
class SecureStorageService {
  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Stores the full encryption envelope for a wallet.
  Future<void> storeWalletCredentials({
    required int walletId,
    required Uint8List encryptedMnemonic,
    required Uint8List salt,
    required int argon2MemoryKib,
    required int argon2Iterations,
    required int argon2Parallelism,
  }) async {
    final prefix = 'wallet_${walletId}';
    await Future.wait([
      _storage.write(key: '${prefix}_encrypted_mnemonic', value: base64.encode(encryptedMnemonic)),
      _storage.write(key: '${prefix}_salt', value: base64.encode(salt)),
      _storage.write(key: '${prefix}_argon2_memory', value: argon2MemoryKib.toString()),
      _storage.write(key: '${prefix}_argon2_iterations', value: argon2Iterations.toString()),
      _storage.write(key: '${prefix}_argon2_parallelism', value: argon2Parallelism.toString()),
    ]);
  }

  /// Reads the wallet credentials, returns null if not found.
  Future<WalletCredentials?> readWalletCredentials({required int walletId}) async {
    final prefix = 'wallet_${walletId}';
    final encMnemonic = await _storage.read(key: '${prefix}_encrypted_mnemonic');
    if (encMnemonic == null) return null;

    final salt = await _storage.read(key: '${prefix}_salt');
    final memory = await _storage.read(key: '${prefix}_argon2_memory');
    final iterations = await _storage.read(key: '${prefix}_argon2_iterations');
    final parallelism = await _storage.read(key: '${prefix}_argon2_parallelism');

    if (salt == null || memory == null || iterations == null || parallelism == null) return null;

    return WalletCredentials(
      encryptedMnemonic: base64.decode(encMnemonic),
      salt: base64.decode(salt),
      argon2MemoryKib: int.parse(memory),
      argon2Iterations: int.parse(iterations),
      argon2Parallelism: int.parse(parallelism),
    );
  }

  /// Deletes all credentials for a wallet. Called on wallet removal.
  Future<void> deleteWalletCredentials({required int walletId}) async {
    final prefix = 'wallet_${walletId}';
    await Future.wait([
      _storage.delete(key: '${prefix}_encrypted_mnemonic'),
      _storage.delete(key: '${prefix}_salt'),
      _storage.delete(key: '${prefix}_argon2_memory'),
      _storage.delete(key: '${prefix}_argon2_iterations'),
      _storage.delete(key: '${prefix}_argon2_parallelism'),
    ]);
  }
}

/// Decrypted credentials read from secure storage.
final class WalletCredentials {
  const WalletCredentials({
    required this.encryptedMnemonic,
    required this.salt,
    required this.argon2MemoryKib,
    required this.argon2Iterations,
    required this.argon2Parallelism,
  });

  final Uint8List encryptedMnemonic;
  final Uint8List salt;
  final int argon2MemoryKib;
  final int argon2Iterations;
  final int argon2Parallelism;
}
```

**Step 4: Run test to verify it passes**

```bash
flutter test test/unit/core/services/secure_storage_service_test.dart -v
```
Expected: PASS

**Step 5: Commit**

```bash
git add lib/src/core/services/ test/unit/core/
git commit -m "feat(storage): add SecureStorageService for wallet credential persistence"
```

---

## Task 3: Auth Domain + Data Layer

The auth system needs:
1. Detect if this is first launch (no wallet exists → route to SetPassword)
2. Verify password by attempting to decrypt the stored mnemonic
3. Optionally set up biometric unlock

**Files:**
- Create: `lib/src/features/auth/domain/auth_state.dart`
- Create: `lib/src/features/auth/data/auth_repository.dart`
- Create: `test/unit/features/auth/data/auth_repository_test.dart`

**Step 1: Create the auth domain state (freezed model)**

```dart
// lib/src/features/auth/domain/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  /// App just launched, checking storage.
  const factory AuthState.loading() = _Loading;

  /// First launch — no wallet exists yet.
  const factory AuthState.firstLaunch() = _FirstLaunch;

  /// Wallet exists, waiting for password.
  const factory AuthState.locked() = _Locked;

  /// Successfully authenticated.
  const factory AuthState.unlocked() = _Unlocked;

  /// Authentication failed.
  const factory AuthState.error(String message) = _Error;
}
```

**Step 2: Run build_runner to generate freezed code**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `auth_state.freezed.dart`.

**Step 3: Write the failing auth repository test**

```dart
// test/unit/features/auth/data/auth_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';

// Mock generated FRB api
class MockCryptoApi extends Mock implements CryptoApi {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late AuthRepository sut;
  late MockSecureStorageService mockStorage;
  late MockAppDatabase mockDb;

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockDb = MockAppDatabase();
    sut = AuthRepository(storage: mockStorage, db: mockDb);
  });

  group('isFirstLaunch', () {
    test('returns true when no wallets in DB', () async {
      when(() => mockDb.walletCount()).thenAnswer((_) async => 0);
      expect(await sut.isFirstLaunch(), isTrue);
    });

    test('returns false when wallets exist', () async {
      when(() => mockDb.walletCount()).thenAnswer((_) async => 1);
      expect(await sut.isFirstLaunch(), isFalse);
    });
  });
}
```

**Step 4: Run test to verify it fails**

```bash
flutter test test/unit/features/auth/data/auth_repository_test.dart -v
```
Expected: FAIL with import error.

**Step 5: Add walletCount() to AppDatabase**

```dart
// Modify lib/src/core/database/app_database.dart
// Add method to _$AppDatabase:
Future<int> walletCount() async {
  final count = await (select(wallets)..limit(1)).get();
  return count.length; // Use count expression for real impl
}
```

Actually use a proper count query:
```dart
Future<int> walletCount() {
  return customSelect(
    'SELECT COUNT(*) AS count FROM wallets',
    readsFrom: {wallets},
  ).map((row) => row.read<int>('count')).getSingle();
}
```

**Step 6: Implement AuthRepository**

```dart
// lib/src/features/auth/data/auth_repository.dart
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';

class AuthRepository {
  const AuthRepository({
    required AppDatabase db,
    required SecureStorageService storage,
  })  : _db = db,
        _storage = storage;

  final AppDatabase _db;
  final SecureStorageService _storage;

  Future<bool> isFirstLaunch() async {
    final count = await _db.walletCount();
    return count == 0;
  }

  /// Verifies a password by attempting mnemonic decryption for [walletId].
  /// Returns true if decryption succeeds (password is correct).
  Future<bool> verifyPassword({
    required int walletId,
    required List<int> passwordBytes,
  }) async {
    final creds = await _storage.readWalletCredentials(walletId: walletId);
    if (creds == null) return false;

    try {
      // Calls Rust: decrypt_mnemonic(...) — throws if password wrong
      await api.decryptMnemonic(
        password: Uint8List.fromList(passwordBytes),
        encryptedMnemonic: creds.encryptedMnemonic,
        salt: creds.salt,
        memoryKib: creds.argon2MemoryKib,
        iterations: creds.argon2Iterations,
        parallelism: creds.argon2Parallelism,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
```

Note: `api` here refers to the FRB-generated `RustLib` API. The exact import path will be `package:unvault/src/rust/api/wallet_api.dart` after codegen. Import paths should be updated once Task 1 is complete and you can see the generated file names.

**Step 7: Run tests to verify they pass**

```bash
flutter test test/unit/features/auth/ -v
```
Expected: PASS

**Step 8: Commit**

```bash
git add lib/src/features/auth/domain/ lib/src/features/auth/data/ lib/src/core/database/app_database.dart test/unit/features/auth/
git commit -m "feat(auth): add auth domain state and repository"
```

---

## Task 4: Auth Application Layer (Notifier)

**Files:**
- Create: `lib/src/features/auth/application/auth_notifier.dart`
- Create: `test/unit/features/auth/application/auth_notifier_test.dart`

**Step 1: Write the failing notifier test**

```dart
// test/unit/features/auth/application/auth_notifier_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is loading', () {
    final state = container.read(authNotifierProvider);
    expect(state, const AuthState.loading());
  });

  test('checkAuthState transitions to firstLaunch when no wallet', () async {
    when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => true);

    await container.read(authNotifierProvider.notifier).checkAuthState();

    expect(container.read(authNotifierProvider), const AuthState.firstLaunch());
  });

  test('checkAuthState transitions to locked when wallet exists', () async {
    when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => false);

    await container.read(authNotifierProvider.notifier).checkAuthState();

    expect(container.read(authNotifierProvider), const AuthState.locked());
  });

  test('unlock with correct password transitions to unlocked', () async {
    when(() => mockRepo.verifyPassword(walletId: any(named: 'walletId'), passwordBytes: any(named: 'passwordBytes')))
        .thenAnswer((_) async => true);

    await container.read(authNotifierProvider.notifier).unlock(
      walletId: 1,
      passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
    );

    expect(container.read(authNotifierProvider), const AuthState.unlocked());
  });

  test('unlock with wrong password stays locked with error', () async {
    when(() => mockRepo.verifyPassword(walletId: any(named: 'walletId'), passwordBytes: any(named: 'passwordBytes')))
        .thenAnswer((_) async => false);

    await container.read(authNotifierProvider.notifier).unlock(
      walletId: 1,
      passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
    );

    expect(container.read(authNotifierProvider), isA<_Error>());
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/unit/features/auth/application/auth_notifier_test.dart -v
```
Expected: FAIL with import error.

**Step 3: Implement AuthNotifier**

```dart
// lib/src/features/auth/application/auth_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.loading();

  Future<void> checkAuthState() async {
    final repo = ref.read(authRepositoryProvider);
    final isFirst = await repo.isFirstLaunch();
    state = isFirst ? const AuthState.firstLaunch() : const AuthState.locked();
  }

  Future<void> unlock({
    required int walletId,
    required List<int> passwordBytes,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final ok = await repo.verifyPassword(walletId: walletId, passwordBytes: passwordBytes);
    state = ok ? const AuthState.unlocked() : const AuthState.error('Incorrect password');
  }

  void lock() {
    state = const AuthState.locked();
  }
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
}

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return const SecureStorageService();
}
```

**Step 4: Run build_runner to generate notifier code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 5: Run tests to verify they pass**

```bash
flutter test test/unit/features/auth/ -v
```
Expected: All PASS.

**Step 6: Commit**

```bash
git add lib/src/features/auth/application/ test/unit/features/auth/application/
git commit -m "feat(auth): add AuthNotifier with loading/locked/unlocked state machine"
```

---

## Task 5: Lock Screen & SetPassword Screen (Auth Presentation)

**Files:**
- Modify: `lib/src/features/auth/presentation/lock_screen.dart`
- Modify: `lib/src/features/auth/presentation/set_password_screen.dart`
- Modify: `lib/src/features/auth/presentation/biometric_setup_screen.dart`
- Create: `test/widget/features/auth/lock_screen_test.dart`
- Create: `test/widget/features/auth/set_password_screen_test.dart`

**Step 1: Write lock screen widget test**

```dart
// test/widget/features/auth/lock_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/features/auth/presentation/lock_screen.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import '../../../helpers/pump_app.dart';

class MockAuthNotifier extends AutoDisposeNotifier<AuthState> with Mock implements AuthNotifier {}

void main() {
  testWidgets('lock screen has password field and unlock button', (tester) async {
    await tester.pumpApp(const LockScreen());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('shows error message when auth fails', (tester) async {
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() {
        final notifier = MockAuthNotifier();
        when(() => notifier.state).thenReturn(const AuthState.error('Incorrect password'));
        return notifier;
      }),
    ]);

    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.text('Incorrect password'), findsOneWidget);
  });
}
```

**Step 2: Run test to verify it fails**

```bash
flutter test test/widget/features/auth/lock_screen_test.dart -v
```
Expected: FAIL (LockScreen is a stub).

**Step 3: Implement LockScreen**

```dart
// lib/src/features/auth/presentation/lock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/routing/route_names.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final password = _controller.text;
    if (password.length < 8) return;

    // NOTE: walletId=1 for MVP (single wallet). Multi-wallet: read active wallet from DB.
    await ref.read(authNotifierProvider.notifier).unlock(
      walletId: 1,
      passwordBytes: password.codeUnits,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (_, next) {
      if (next is _Unlocked) context.goNamed(RouteNames.walletList);
    });

    final state = ref.watch(authNotifierProvider);
    final errorMsg = state is _Error ? state.message : null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('UnVault', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: errorMsg,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _unlock,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Implement SetPasswordScreen**

The set-password screen creates the initial password. It does NOT interact with Rust directly — that happens during wallet creation. This screen collects + validates the password and hands it off to the wallet creation flow.

```dart
// lib/src/features/auth/presentation/set_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/routing/route_names.dart';

/// Screen shown on first launch to collect the wallet encryption password.
/// Password is passed to the wallet creation flow via route extra.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _proceed() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    // Pass password to wallet creation screen
    context.goNamed(RouteNames.createWallet, extra: {'password': password});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password (min 8 chars)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _proceed,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 5: Run widget tests**

```bash
flutter test test/widget/features/auth/ -v
```
Expected: PASS.

**Step 6: Commit**

```bash
git add lib/src/features/auth/presentation/ test/widget/features/auth/
git commit -m "feat(auth): implement lock screen and set-password screen"
```

---

## Task 6: Wallet Domain + Repository

**Files:**
- Create: `lib/src/features/wallet/domain/wallet_model.dart`
- Create: `lib/src/core/database/daos/wallets_dao.dart`
- Create: `lib/src/features/wallet/data/wallet_repository.dart`
- Create: `test/unit/features/wallet/data/wallet_repository_test.dart`

**Step 1: Write wallet domain model (freezed)**

```dart
// lib/src/features/wallet/domain/wallet_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.freezed.dart';

@freezed
class WalletModel with _$WalletModel {
  const factory WalletModel({
    required int id,
    required String name,
    required String firstAddress,
    required bool isBackedUp,
    required DateTime createdAt,
  }) = _WalletModel;
}
```

**Step 2: Create WalletsDao**

```dart
// lib/src/core/database/daos/wallets_dao.dart
import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/wallets_table.dart';

part 'wallets_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletsDao extends DatabaseAccessor<AppDatabase> with _$WalletsDaoMixin {
  WalletsDao(super.db);

  Future<List<Wallet>> getAllWallets() => select(wallets).get();

  Future<Wallet?> getWalletById(int id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWallet(WalletsCompanion wallet) => into(wallets).insert(wallet);

  Future<void> markBackedUp(int id) async {
    await (update(wallets)..where((w) => w.id.equals(id)))
        .write(const WalletsCompanion(isBackedUp: Value(true)));
  }

  Future<int> countWallets() {
    return customSelect('SELECT COUNT(*) AS count FROM wallets', readsFrom: {wallets})
        .map((row) => row.read<int>('count'))
        .getSingle();
  }
}
```

**Step 3: Register WalletsDao in AppDatabase**

```dart
// Modify lib/src/core/database/app_database.dart
@DriftDatabase(tables: [Wallets, Accounts, Transactions, Networks], daos: [WalletsDao])
class AppDatabase extends _$AppDatabase {
  // ... existing code ...
  WalletsDao get walletsDao => WalletsDao(this);
}
```

**Step 4: Write wallet repository test**

```dart
// test/unit/features/wallet/data/wallet_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';

class MockWalletsDao extends Mock implements WalletsDao {}
class MockSecureStorageService extends Mock implements SecureStorageService {}
// FRB mock: class MockWalletApi extends Mock implements WalletApi {}

void main() {
  late WalletRepository sut;
  late MockWalletsDao mockDao;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockDao = MockWalletsDao();
    mockStorage = MockSecureStorageService();
    sut = WalletRepository(dao: mockDao, storage: mockStorage);
  });

  group('createWallet', () {
    test('throws PasswordTooShortException for password < 8 chars', () async {
      await expectLater(
        () => sut.createWallet(name: 'My Wallet', passwordBytes: [1, 2, 3]),
        throwsA(isA<PasswordTooShortException>()),
      );
    });
  });
}
```

**Step 5: Run test to verify it fails**

```bash
flutter test test/unit/features/wallet/data/wallet_repository_test.dart -v
```
Expected: FAIL with import error.

**Step 6: Implement WalletRepository**

```dart
// lib/src/features/wallet/data/wallet_repository.dart
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/database/tables/wallets_table.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
// After FRB codegen:
// import 'package:unvault/src/rust/api/wallet_api.dart';

class WalletRepository {
  const WalletRepository({
    required WalletsDao dao,
    required SecureStorageService storage,
  })  : _dao = dao,
        _storage = storage;

  final WalletsDao _dao;
  final SecureStorageService _storage;

  Future<List<WalletModel>> getWallets() async {
    final rows = await _dao.getAllWallets();
    return rows.map((w) => WalletModel(
      id: w.id,
      name: w.name,
      firstAddress: '', // address stored in Accounts table
      isBackedUp: w.isBackedUp,
      createdAt: w.createdAt,
    )).toList();
  }

  /// Creates a new wallet: calls Rust to generate mnemonic + encrypt it,
  /// stores encrypted bytes in secure storage, saves wallet row in DB.
  ///
  /// Returns the new wallet's ID and the mnemonic bytes (must be zeroized by caller).
  Future<WalletCreationResult> createWallet({
    required String name,
    required List<int> passwordBytes,
    int wordCount = 12,
  }) async {
    if (passwordBytes.length < 8) throw const PasswordTooShortException();

    // 1. Call Rust FFI (after Task 1 codegen):
    //    final response = await createWalletFfi(
    //      password: Uint8List.fromList(passwordBytes),
    //      wordCount: wordCount,
    //    );

    // 2. Insert wallet row into DB
    final walletId = await _dao.insertWallet(
      WalletsCompanion.insert(name: name),
    );

    // 3. Store encrypted credentials in secure storage
    //    await _storage.storeWalletCredentials(
    //      walletId: walletId,
    //      encryptedMnemonic: Uint8List.fromList(response.encryptedMnemonic),
    //      salt: Uint8List.fromList(response.salt),
    //      argon2MemoryKib: response.argon2MemoryKib,
    //      argon2Iterations: response.argon2Iterations,
    //      argon2Parallelism: response.argon2Parallelism,
    //    );

    // 4. Return result including mnemonic bytes for backup display
    return WalletCreationResult(
      walletId: walletId,
      firstAddress: '', // response.firstAddress,
      mnemonicBytes: Uint8List(0), // Uint8List.fromList(response.mnemonicBytes),
    );
  }

  Future<void> markBackedUp(int walletId) async {
    await _dao.markBackedUp(walletId);
  }
}

final class WalletCreationResult {
  const WalletCreationResult({
    required this.walletId,
    required this.firstAddress,
    required this.mnemonicBytes,
  });

  final int walletId;
  final String firstAddress;
  final Uint8List mnemonicBytes; // MUST be zeroized by caller after backup display
}
```

**Step 7: Run build_runner for freezed and drift**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 8: Run tests to verify they pass**

```bash
flutter test test/unit/features/wallet/ -v
```
Expected: PASS.

**Step 9: Commit**

```bash
git add lib/src/features/wallet/ lib/src/core/database/daos/ test/unit/features/wallet/
git commit -m "feat(wallet): add wallet domain model, DAO, and repository"
```

---

## Task 7: Wallet Notifier + Create/Import Screens

**Files:**
- Create: `lib/src/features/wallet/application/wallet_notifier.dart`
- Modify: `lib/src/features/wallet/presentation/create_wallet_screen.dart`
- Modify: `lib/src/features/wallet/presentation/import_wallet_screen.dart`
- Modify: `lib/src/features/wallet/presentation/wallet_list_screen.dart`
- Create: `test/widget/features/wallet/create_wallet_screen_test.dart`

**Step 1: Implement WalletNotifier**

```dart
// lib/src/features/wallet/application/wallet_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';

part 'wallet_notifier.g.dart';

@riverpod
Future<List<WalletModel>> walletList(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWallets();
}

@riverpod
WalletRepository walletRepository(Ref ref) {
  return WalletRepository(
    dao: ref.watch(appDatabaseProvider).walletsDao,
    storage: ref.watch(secureStorageServiceProvider),
  );
}
```

**Step 2: Implement CreateWalletScreen**

```dart
// lib/src/features/wallet/presentation/create_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key, required this.passwordBytes});

  final List<int> passwordBytes; // passed from SetPasswordScreen via route extra

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final _nameController = TextEditingController(text: 'My Wallet');
  int _wordCount = 12;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final result = await repo.createWallet(
        name: _nameController.text,
        passwordBytes: widget.passwordBytes,
        wordCount: _wordCount,
      );
      ref.invalidate(walletListProvider);
      if (mounted) {
        // Navigate to backup/show, passing the mnemonic bytes
        context.goNamed(
          RouteNames.backupShow,
          extra: {
            'walletId': result.walletId,
            'mnemonicBytes': result.mnemonicBytes,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallet Name'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 12, label: Text('12 words')),
                ButtonSegment(value: 24, label: Text('24 words')),
              ],
              selected: {_wordCount},
              onSelectionChanged: (v) => setState(() => _wordCount = v.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Create Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Implement ImportWalletScreen**

```dart
// lib/src/features/wallet/presentation/import_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({super.key, required this.passwordBytes});

  final List<int> passwordBytes;

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final _phraseController = TextEditingController();
  final _nameController = TextEditingController(text: 'Imported Wallet');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phraseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final phrase = _phraseController.text.trim();
    if (phrase.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.importWallet(
        name: _nameController.text,
        phraseBytes: phrase.codeUnits,
        passwordBytes: widget.passwordBytes,
      );
      ref.invalidate(walletListProvider);
      if (mounted) context.goNamed(RouteNames.walletList);
    } catch (e) {
      setState(() => _error = 'Invalid mnemonic phrase');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallet Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phraseController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Recovery Phrase (12 or 24 words)',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _import,
              child: _loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Implement WalletListScreen**

```dart
// lib/src/features/wallet/presentation/wallet_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.goNamed(RouteNames.createWallet),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) => wallets.isEmpty
            ? const Center(child: Text('No wallets. Tap + to create one.'))
            : ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  return ListTile(
                    title: Text(w.name),
                    subtitle: Text(w.firstAddress.isEmpty ? 'Loading...' : w.firstAddress),
                    trailing: w.isBackedUp ? null : const Icon(Icons.warning, color: Colors.orange),
                    onTap: () {/* navigate to wallet detail */},
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

**Step 5: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues.

**Step 6: Run all widget tests**

```bash
flutter test test/widget/ -v
```
Expected: All PASS.

**Step 7: Commit**

```bash
git add lib/src/features/wallet/ test/widget/features/wallet/
git commit -m "feat(wallet): implement wallet list, create, and import screens"
```

---

## Task 8: Backup Feature

**Files:**
- Modify: `lib/src/features/backup/presentation/show_mnemonic_screen.dart`
- Modify: `lib/src/features/backup/presentation/verify_mnemonic_screen.dart`
- Create: `lib/src/features/backup/application/backup_notifier.dart`
- Create: `test/widget/features/backup/show_mnemonic_screen_test.dart`

**Step 1: Implement ShowMnemonicScreen**

The mnemonic bytes are passed via route extra. The screen displays them as a numbered grid, then navigates to verify.

```dart
// lib/src/features/backup/presentation/show_mnemonic_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/routing/route_names.dart';

class ShowMnemonicScreen extends StatelessWidget {
  const ShowMnemonicScreen({
    super.key,
    required this.walletId,
    required this.mnemonicBytes,
  });

  final int walletId;
  final Uint8List mnemonicBytes;

  @override
  Widget build(BuildContext context) {
    // SECURITY: Convert bytes to words only for display, never store as String
    final phrase = String.fromCharCodes(mnemonicBytes);
    final words = phrase.split(' ');

    return Scaffold(
      appBar: AppBar(title: const Text('Backup Recovery Phrase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Write down these words in order and store them safely. '
              'They are the only way to recover your wallet.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: words.length,
                itemBuilder: (ctx, i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          words[i],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.goNamed(
                  RouteNames.backupVerify,
                  extra: {
                    'walletId': walletId,
                    'words': words,
                  },
                );
              },
              child: const Text("I've written it down"),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: Implement VerifyMnemonicScreen**

Picks 3 random word positions and asks user to fill them in. If correct, marks wallet as backed up.

```dart
// lib/src/features/backup/presentation/verify_mnemonic_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class VerifyMnemonicScreen extends ConsumerStatefulWidget {
  const VerifyMnemonicScreen({
    super.key,
    required this.walletId,
    required this.words,
  });

  final int walletId;
  final List<String> words;

  @override
  ConsumerState<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends ConsumerState<VerifyMnemonicScreen> {
  late final List<int> _challengeIndices;
  late final List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random.secure();
    final indices = List.generate(widget.words.length, (i) => i)..shuffle(rng);
    _challengeIndices = indices.take(3).toList()..sort();
    _controllers = List.generate(3, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    for (var i = 0; i < _challengeIndices.length; i++) {
      if (_controllers[i].text.trim() != widget.words[_challengeIndices[i]]) {
        setState(() => _error = 'Incorrect. Check word ${_challengeIndices[i] + 1}.');
        return;
      }
    }

    // Mark wallet as backed up in DB
    await ref.read(walletRepositoryProvider).markBackedUp(widget.walletId);
    ref.invalidate(walletListProvider);
    if (mounted) context.goNamed(RouteNames.walletList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Recovery Phrase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter the requested words to confirm your backup.'),
            const SizedBox(height: 24),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _controllers[i],
                decoration: InputDecoration(
                  labelText: 'Word #${_challengeIndices[i] + 1}',
                ),
              ),
            )),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _verify,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues.

**Step 4: Commit**

```bash
git add lib/src/features/backup/ test/widget/features/backup/
git commit -m "feat(backup): implement show mnemonic and verify mnemonic screens"
```

---

## Task 9: Smart Router — Auth Guard

The router needs to redirect based on auth state. On first launch → `/set-password`. On subsequent launches → `/lock`. After unlock → `/wallets`.

**Files:**
- Modify: `lib/src/routing/app_router.dart`
- Modify: `lib/main.dart` (trigger checkAuthState on init)

**Step 1: Update router with redirect logic**

```dart
// lib/src/routing/app_router.dart (update routerProvider)
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/lock',
    redirect: (context, state) {
      final isLoading = authState is _Loading;
      final isFirstLaunch = authState is _FirstLaunch;
      final isUnlocked = authState is _Unlocked;

      if (isLoading) return null; // wait
      if (isFirstLaunch && state.matchedLocation != '/set-password') return '/set-password';
      if (!isUnlocked && state.matchedLocation == '/wallets') return '/lock';
      if (isUnlocked && state.matchedLocation == '/lock') return '/wallets';
      return null;
    },
    routes: [...], // existing routes unchanged
  );
}
```

**Step 2: Trigger checkAuthState on app start**

Update `lib/app.dart` to call checkAuthState on first build:

```dart
// lib/app.dart
class UnVaultApp extends ConsumerWidget {
  const UnVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check auth state on first build
    ref.listen(authNotifierProvider, (_, __) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkAuthState();
    });
    // ... rest unchanged
  }
}
```

**Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues.

**Step 4: Commit**

```bash
git add lib/src/routing/ lib/app.dart
git commit -m "feat(router): add auth guard redirects for first-launch and lock state"
```

---

## Task 10: Integration Test — Full Wallet Creation Flow

**Files:**
- Create: `integration_test/wallet_creation_test.dart`

**Step 1: Write integration test**

```dart
// integration_test/wallet_creation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unvault/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  test('FRB bridge: generate and validate mnemonic roundtrip', () async {
    // Call Rust via generated FFI
    final mnemonicBytes = generateMnemonic(wordCount: 12);
    expect(mnemonicBytes.length, greaterThan(0));

    final isValid = validateMnemonic(phraseBytes: mnemonicBytes);
    expect(isValid, isTrue);
  });

  test('FRB bridge: create wallet returns valid address', () async {
    final response = await createWallet(
      password: Uint8List.fromList('test_password_123'.codeUnits),
      wordCount: 12,
    );

    expect(response.firstAddress, startsWith('0x'));
    expect(response.firstAddress.length, equals(42));
    expect(response.salt.length, equals(16));
    expect(response.encryptedMnemonic, isNotEmpty);
  });
}
```

**Step 2: Run integration test on simulator**

```bash
flutter test integration_test/wallet_creation_test.dart
```
Expected: PASS (real Rust FFI called).

**Step 3: Commit**

```bash
git add integration_test/
git commit -m "test(integration): add FFI bridge and wallet creation integration tests"
```

---

## Task 11: Final Verification

**Step 1: Run all Rust tests**

```bash
cargo test --manifest-path rust/Cargo.toml --all-targets
```
Expected: 132 tests, all PASS.

**Step 2: Run all Flutter tests**

```bash
flutter test
```
Expected: All PASS, no failures.

**Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: No issues found.

**Step 4: Run clippy on Rust**

```bash
cargo clippy --manifest-path rust/Cargo.toml --all-targets -- -D warnings
```
Expected: No warnings.

**Step 5: Final commit**

```bash
git add .
git commit -m "feat: core wallet MVP complete — FRB bridge + auth + create/import + backup"
```

---

## Implementation Notes

### FRB Codegen Details (Task 1)
- FRB v2 requires `flutter_rust_bridge_codegen` CLI: install with `cargo install flutter_rust_bridge_codegen`
- All API functions without `#[frb(sync)]` become async Dart futures automatically
- Generated files live in `lib/src/rust/` — import paths will be `package:unvault/src/rust/api/wallet_api.dart` etc.
- After any Rust API change, re-run `flutter_rust_bridge_codegen generate` and commit generated files

### Security Notes
- `mnemonicBytes` returned from `createWallet` must be passed to `ShowMnemonicScreen` and NOT stored anywhere after display
- Password is collected in `SetPasswordScreen`, passed as route extra to `CreateWalletScreen`, used once for Rust encryption, then discarded
- `flutter_secure_storage` encrypts using iOS Keychain / Android Keystore — never logs keys
- The `WalletRepository.createWallet` stub (Task 6 Step 6) has placeholder comments — fill in actual FRB API calls once Task 1 is complete

### What Comes After MVP
After these 11 tasks, the app supports:
- Create wallet (Rust BIP-39 + Argon2id + AES-GCM)
- Import wallet from mnemonic
- Password lock/unlock
- Mnemonic backup and verification

**Phase 2 backlog (next plan):**
1. Transfer: `send_screen.dart` → `confirm_transaction_screen.dart` → Rust EIP-1559 signing → broadcast via RPC
2. Balance: HTTP call to RPC `eth_getBalance` + display in wallet list
3. Network management: `network_management_screen.dart` + NetworksDao + seed built-in chains
4. Transaction history: `history_screen.dart` + TransactionsDao + polling
5. Settings: biometric unlock, app lock timer, change password, export wallet
