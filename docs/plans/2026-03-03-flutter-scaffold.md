# Flutter 项目脚手架 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Scaffold the complete Flutter project skeleton for UnVault so that `flutter run` launches an empty shell APP with full directory structure, routing, and dependency configuration.

**Architecture:** Feature-first with 4-layer separation (domain/data/application/presentation). Riverpod 3.x for state, go_router for routing, drift for local DB, freezed for models. Rust core already complete — this plan only creates Flutter side.

**Tech Stack:** Flutter 3.38.x, Dart 3.10.x, Riverpod 3.x, go_router 14.x, freezed 3.x, drift 2.x, flutter_rust_bridge 2.x

---

## Task 1: Flutter project creation

Create the Flutter project in the existing repo root, preserving existing files (`rust/`, `lib/CLAUDE.md`, `.gitignore`, `docs/`, `CLAUDE.md`).

**Step 1: Back up lib/CLAUDE.md**

```bash
cp lib/CLAUDE.md /tmp/unvault_lib_claude_md_backup
```

**Step 2: Run flutter create**

```bash
cd /Users/cyber/restox/UnVault
flutter create --org com.unvault --project-name unvault --platforms ios,android .
```

This generates: `android/`, `ios/`, `lib/main.dart`, `pubspec.yaml`, `analysis_options.yaml`, `test/widget_test.dart`, etc. It will NOT overwrite existing files like `.gitignore`, `CLAUDE.md`, `rust/`.

**Step 3: Restore lib/CLAUDE.md if overwritten**

```bash
cp /tmp/unvault_lib_claude_md_backup lib/CLAUDE.md
```

**Step 4: Delete generated sample code**

```bash
rm -f test/widget_test.dart
```

**Step 5: Verify flutter project works**

```bash
flutter pub get
flutter analyze
```

Expected: Clean project compiles with no analysis errors.

**Step 6: Commit**

```bash
git add android/ ios/ lib/main.dart pubspec.yaml pubspec.lock analysis_options.yaml .metadata web/ linux/ macos/ windows/ 2>/dev/null
git add lib/CLAUDE.md
git commit -m "chore(flutter): initialize Flutter project with flutter create"
```

Note: `flutter create` may generate platform dirs beyond ios/android. Only add what exists. The commit captures the vanilla Flutter project before customization.

---

## Task 2: pubspec.yaml — dependencies and project metadata

Replace the auto-generated `pubspec.yaml` with the reviewed dependency set.

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Write pubspec.yaml**

Replace entire content of `pubspec.yaml` with:

```yaml
name: unvault
description: "UnVault - Secure Ethereum HD Wallet"
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter

  # State management (Riverpod 3.x)
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0

  # Routing
  go_router: ^14.8.0

  # Immutable data models (freezed 3.x)
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0

  # Local database (non-sensitive data only)
  drift: ^2.22.0
  drift_flutter: ^0.2.0

  # Secure storage (Keychain / Keystore)
  flutter_secure_storage: ^9.2.0

  # Biometric authentication
  local_auth: ^2.3.0

  # FFI bridge to Rust core
  flutter_rust_bridge: ^2.7.0

  # Utilities
  path_provider: ^2.1.0
  path: ^1.9.0

  # Localization
  flutter_localizations:
    sdk: flutter
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  riverpod_generator: ^3.0.0
  freezed: ^3.0.0
  json_serializable: ^6.9.0
  build_runner: ^2.4.0
  drift_dev: ^2.22.0

  # Linting
  very_good_analysis: ^7.0.0
  riverpod_lint: ^3.0.0
  custom_lint: ^0.7.0

  # Testing
  mocktail: ^1.0.0

flutter:
  uses-material-design: true
  generate: true
```

**Step 2: Run pub get and resolve**

```bash
flutter pub get
```

If any version conflicts, adjust constraints to resolve. Record final versions from `pubspec.lock`.

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): configure Flutter dependencies per architect review

Riverpod 3.x, freezed 3.x, drift + drift_flutter, go_router,
very_good_analysis, riverpod_lint, flutter_secure_storage, local_auth."
```

---

## Task 3: Configuration files

Create `analysis_options.yaml`, `build.yaml`, `flutter_rust_bridge.yaml`, `l10n.yaml`.

**Files:**
- Modify: `analysis_options.yaml` (replace flutter create default)
- Create: `build.yaml`
- Create: `flutter_rust_bridge.yaml`
- Create: `l10n.yaml`

**Step 1: Write analysis_options.yaml**

```yaml
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.drift.dart"
    - "lib/src/rust/**"
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    public_member_api_docs: false
```

**Step 2: Write build.yaml**

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
      drift_dev:
        options:
          generate_connect_constructor: true
```

**Step 3: Write flutter_rust_bridge.yaml**

```yaml
rust_input: rust/src/api/*.rs
dart_output: lib/src/rust/
```

**Step 4: Write l10n.yaml**

```yaml
arb-dir: lib/src/localization
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/src/localization/generated
synthetic-package: false
```

**Step 5: Verify analysis passes**

```bash
flutter analyze
```

**Step 6: Commit**

```bash
git add analysis_options.yaml build.yaml flutter_rust_bridge.yaml l10n.yaml
git commit -m "chore(config): add analysis_options, build.yaml, FRB config, l10n config"
```

---

## Task 4: Localization files

Create ARB localization files so that `flutter gen-l10n` can run.

**Files:**
- Create: `lib/src/localization/app_en.arb`
- Create: `lib/src/localization/app_zh.arb`

**Step 1: Create localization directory**

```bash
mkdir -p lib/src/localization
```

**Step 2: Write app_en.arb**

```json
{
  "@@locale": "en",
  "appTitle": "UnVault",
  "@appTitle": {
    "description": "The title of the application"
  },
  "walletListTitle": "Wallets",
  "createWallet": "Create Wallet",
  "importWallet": "Import Wallet",
  "unlock": "Unlock",
  "setPassword": "Set Password",
  "confirmPassword": "Confirm Password",
  "backupMnemonic": "Backup Mnemonic",
  "verifyMnemonic": "Verify Mnemonic",
  "send": "Send",
  "receive": "Receive",
  "confirmTransaction": "Confirm Transaction",
  "transactionHistory": "Transaction History",
  "settings": "Settings",
  "networkManagement": "Network Management"
}
```

**Step 3: Write app_zh.arb**

```json
{
  "@@locale": "zh",
  "appTitle": "UnVault",
  "walletListTitle": "钱包",
  "createWallet": "创建钱包",
  "importWallet": "导入钱包",
  "unlock": "解锁",
  "setPassword": "设置密码",
  "confirmPassword": "确认密码",
  "backupMnemonic": "备份助记词",
  "verifyMnemonic": "验证助记词",
  "send": "发送",
  "receive": "收款",
  "confirmTransaction": "确认交易",
  "transactionHistory": "交易记录",
  "settings": "设置",
  "networkManagement": "网络管理"
}
```

**Step 4: Generate localization code**

```bash
flutter gen-l10n
```

**Step 5: Commit**

```bash
git add lib/src/localization/
git commit -m "feat(l10n): add English and Chinese localization files"
```

---

## Task 5: Core infrastructure — database tables, providers, constants, exceptions

**Files:**
- Create: `lib/src/core/database/app_database.dart`
- Create: `lib/src/core/database/tables/wallets_table.dart`
- Create: `lib/src/core/database/tables/accounts_table.dart`
- Create: `lib/src/core/database/tables/transactions_table.dart`
- Create: `lib/src/core/database/tables/networks_table.dart`
- Create: `lib/src/core/providers/app_providers.dart`
- Create: `lib/src/core/constants/chain_config.dart`
- Create: `lib/src/core/exceptions/app_exceptions.dart`
- Create: Various `.gitkeep` for empty directories

**Step 1: Create all core directories**

```bash
mkdir -p lib/src/core/{database/{tables,daos,migrations},providers,common_widgets,constants,exceptions,utils,extensions}
mkdir -p lib/src/rust
```

**Step 2: Write drift table — wallets_table.dart**

```dart
import 'package:drift/drift.dart';

class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isBackedUp => boolean().withDefault(const Constant(false))();
}
```

**Step 3: Write drift table — accounts_table.dart**

```dart
import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get derivationIndex => integer()();
  TextColumn get address => text().withLength(min: 42, max: 42)();
  TextColumn get name => text().withLength(min: 1, max: 50).nullable()();
}
```

Note: This file needs to import `wallets_table.dart` for the foreign key reference. The reference uses the `Wallets` table class.

**Step 4: Write drift table — transactions_table.dart**

```dart
import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get hash => text()();
  TextColumn get fromAddress => text()();
  TextColumn get toAddress => text().nullable()();
  TextColumn get value => text()();
  IntColumn get chainId => integer()();
  TextColumn get status => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {hash};
}
```

**Step 5: Write drift table — networks_table.dart**

```dart
import 'package:drift/drift.dart';

class Networks extends Table {
  IntColumn get chainId => integer()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  IntColumn get decimals => integer().withDefault(const Constant(18))();
  TextColumn get rpcUrl => text()();
  TextColumn get explorerUrl => text()();
  TextColumn get gasType => text().withDefault(const Constant('eip1559'))();
  BoolColumn get isTestnet => boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {chainId};
}
```

**Step 6: Write app_database.dart**

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/wallets_table.dart';
import 'tables/accounts_table.dart';
import 'tables/transactions_table.dart';
import 'tables/networks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Accounts, Transactions, Networks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'unvault');
  }
}
```

**Step 7: Write app_providers.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';

part 'app_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
```

**Step 8: Write chain_config.dart**

```dart
class ChainConfig {
  const ChainConfig({
    required this.chainId,
    required this.name,
    required this.symbol,
    this.decimals = 18,
    required this.rpcUrls,
    required this.explorerUrl,
    this.gasType = GasType.eip1559,
    this.isTestnet = false,
  });

  final int chainId;
  final String name;
  final String symbol;
  final int decimals;
  final List<String> rpcUrls;
  final String explorerUrl;
  final GasType gasType;
  final bool isTestnet;
}

enum GasType { eip1559, legacy }

class BuiltInChains {
  BuiltInChains._();

  static const ethereumMainnet = ChainConfig(
    chainId: 1,
    name: 'Ethereum',
    symbol: 'ETH',
    rpcUrls: ['https://eth.llamarpc.com', 'https://rpc.ankr.com/eth'],
    explorerUrl: 'https://etherscan.io',
  );

  static const sepolia = ChainConfig(
    chainId: 11155111,
    name: 'Sepolia',
    symbol: 'ETH',
    rpcUrls: [
      'https://rpc.sepolia.org',
      'https://rpc.ankr.com/eth_sepolia',
    ],
    explorerUrl: 'https://sepolia.etherscan.io',
    isTestnet: true,
  );

  static const polygon = ChainConfig(
    chainId: 137,
    name: 'Polygon',
    symbol: 'POL',
    rpcUrls: [
      'https://polygon-rpc.com',
      'https://rpc.ankr.com/polygon',
    ],
    explorerUrl: 'https://polygonscan.com',
  );

  static const arbitrum = ChainConfig(
    chainId: 42161,
    name: 'Arbitrum One',
    symbol: 'ETH',
    rpcUrls: [
      'https://arb1.arbitrum.io/rpc',
      'https://rpc.ankr.com/arbitrum',
    ],
    explorerUrl: 'https://arbiscan.io',
  );

  static const optimism = ChainConfig(
    chainId: 10,
    name: 'Optimism',
    symbol: 'ETH',
    rpcUrls: [
      'https://mainnet.optimism.io',
      'https://rpc.ankr.com/optimism',
    ],
    explorerUrl: 'https://optimistic.etherscan.io',
  );

  static const base = ChainConfig(
    chainId: 8453,
    name: 'Base',
    symbol: 'ETH',
    rpcUrls: [
      'https://mainnet.base.org',
      'https://base.llamarpc.com',
    ],
    explorerUrl: 'https://basescan.org',
  );

  static const bsc = ChainConfig(
    chainId: 56,
    name: 'BNB Smart Chain',
    symbol: 'BNB',
    rpcUrls: [
      'https://bsc-dataseed.binance.org',
      'https://rpc.ankr.com/bsc',
    ],
    explorerUrl: 'https://bscscan.com',
    gasType: GasType.legacy,
  );

  static const avalanche = ChainConfig(
    chainId: 43114,
    name: 'Avalanche C-Chain',
    symbol: 'AVAX',
    rpcUrls: [
      'https://api.avax.network/ext/bc/C/rpc',
      'https://rpc.ankr.com/avalanche',
    ],
    explorerUrl: 'https://snowtrace.io',
    gasType: GasType.legacy,
  );

  static const all = [
    ethereumMainnet,
    sepolia,
    polygon,
    arbitrum,
    optimism,
    base,
    bsc,
    avalanche,
  ];
}
```

**Step 9: Write app_exceptions.dart**

```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PasswordTooShortException extends AppException {
  const PasswordTooShortException()
      : super('Password must be at least 8 characters');
}

class WalletNotFoundException extends AppException {
  const WalletNotFoundException() : super('Wallet not found');
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class RustBridgeException extends AppException {
  const RustBridgeException(super.message);
}
```

**Step 10: Add .gitkeep files for empty directories**

```bash
touch lib/src/core/common_widgets/.gitkeep
touch lib/src/core/utils/.gitkeep
touch lib/src/core/extensions/.gitkeep
touch lib/src/core/database/daos/.gitkeep
touch lib/src/core/database/migrations/.gitkeep
touch lib/src/rust/.gitkeep
```

**Step 11: Commit**

```bash
git add lib/src/core/ lib/src/rust/
git commit -m "feat(core): add database tables, providers, chain config, and exceptions"
```

---

## Task 6: Routing — go_router with auth guard

**Files:**
- Create: `lib/src/routing/app_router.dart`
- Create: `lib/src/routing/route_names.dart`

**Step 1: Write route_names.dart**

```dart
abstract final class RouteNames {
  static const lock = 'lock';
  static const setPassword = 'set-password';
  static const biometricSetup = 'biometric-setup';
  static const walletList = 'wallet-list';
  static const createWallet = 'create-wallet';
  static const importWallet = 'import-wallet';
  static const backupShow = 'backup-show';
  static const backupVerify = 'backup-verify';
  static const send = 'send';
  static const confirmTransaction = 'confirm-transaction';
  static const receive = 'receive';
  static const history = 'history';
  static const settings = 'settings';
  static const networkManagement = 'network-management';
}
```

**Step 2: Write app_router.dart**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'route_names.dart';
import '../features/auth/presentation/lock_screen.dart';
import '../features/auth/presentation/set_password_screen.dart';
import '../features/auth/presentation/biometric_setup_screen.dart';
import '../features/wallet/presentation/wallet_list_screen.dart';
import '../features/wallet/presentation/create_wallet_screen.dart';
import '../features/wallet/presentation/import_wallet_screen.dart';
import '../features/backup/presentation/show_mnemonic_screen.dart';
import '../features/backup/presentation/verify_mnemonic_screen.dart';
import '../features/transfer/presentation/send_screen.dart';
import '../features/transfer/presentation/confirm_transaction_screen.dart';
import '../features/transfer/presentation/receive_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/network/presentation/network_management_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/lock',
    routes: [
      GoRoute(
        path: '/lock',
        name: RouteNames.lock,
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/set-password',
        name: RouteNames.setPassword,
        builder: (context, state) => const SetPasswordScreen(),
      ),
      GoRoute(
        path: '/biometric-setup',
        name: RouteNames.biometricSetup,
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: '/wallets',
        name: RouteNames.walletList,
        builder: (context, state) => const WalletListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: RouteNames.createWallet,
            builder: (context, state) => const CreateWalletScreen(),
          ),
          GoRoute(
            path: 'import',
            name: RouteNames.importWallet,
            builder: (context, state) => const ImportWalletScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/backup/show',
        name: RouteNames.backupShow,
        builder: (context, state) => const ShowMnemonicScreen(),
      ),
      GoRoute(
        path: '/backup/verify',
        name: RouteNames.backupVerify,
        builder: (context, state) => const VerifyMnemonicScreen(),
      ),
      GoRoute(
        path: '/transfer/send',
        name: RouteNames.send,
        builder: (context, state) => const SendScreen(),
      ),
      GoRoute(
        path: '/transfer/confirm',
        name: RouteNames.confirmTransaction,
        builder: (context, state) => const ConfirmTransactionScreen(),
      ),
      GoRoute(
        path: '/transfer/receive',
        name: RouteNames.receive,
        builder: (context, state) => const ReceiveScreen(),
      ),
      GoRoute(
        path: '/history',
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'network',
            name: RouteNames.networkManagement,
            builder: (context, state) => const NetworkManagementScreen(),
          ),
        ],
      ),
    ],
  );
}
```

**Step 3: Commit**

```bash
git add lib/src/routing/
git commit -m "feat(routing): add go_router route tree with all screen routes"
```

---

## Task 7: Feature module directories + placeholder screens

Create all 7 feature modules with their layer directories and placeholder screen files.

**Step 1: Create all feature directories**

```bash
# wallet — full 4-layer
mkdir -p lib/src/features/wallet/{domain,data,application,presentation/widgets}

# auth — full 4-layer
mkdir -p lib/src/features/auth/{domain,data,application,presentation}

# backup — domain + application + presentation
mkdir -p lib/src/features/backup/{domain,application,presentation}

# transfer — full 4-layer
mkdir -p lib/src/features/transfer/{domain,data,application,presentation}

# history — domain + data + presentation
mkdir -p lib/src/features/history/{domain,data,presentation}

# network — domain + data + presentation
mkdir -p lib/src/features/network/{domain,data,presentation}

# settings — domain + data + presentation
mkdir -p lib/src/features/settings/{domain,data,presentation}
```

**Step 2: Write placeholder screens**

Every screen follows this pattern — a `ConsumerWidget` with a minimal Scaffold. Below is the template, repeated for each screen. The actual file content for each:

**`lib/src/features/auth/presentation/lock_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock')),
      body: const Center(child: Text('Lock Screen — TODO')),
    );
  }
}
```

**`lib/src/features/auth/presentation/set_password_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetPasswordScreen extends ConsumerWidget {
  const SetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Password')),
      body: const Center(child: Text('Set Password — TODO')),
    );
  }
}
```

**`lib/src/features/auth/presentation/biometric_setup_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricSetupScreen extends ConsumerWidget {
  const BiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Setup')),
      body: const Center(child: Text('Biometric Setup — TODO')),
    );
  }
}
```

**`lib/src/features/wallet/presentation/wallet_list_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      body: const Center(child: Text('Wallet List — TODO')),
    );
  }
}
```

**`lib/src/features/wallet/presentation/create_wallet_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateWalletScreen extends ConsumerWidget {
  const CreateWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wallet')),
      body: const Center(child: Text('Create Wallet — TODO')),
    );
  }
}
```

**`lib/src/features/wallet/presentation/import_wallet_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportWalletScreen extends ConsumerWidget {
  const ImportWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: const Center(child: Text('Import Wallet — TODO')),
    );
  }
}
```

**`lib/src/features/backup/presentation/show_mnemonic_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShowMnemonicScreen extends ConsumerWidget {
  const ShowMnemonicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Mnemonic')),
      body: const Center(child: Text('Show Mnemonic — TODO')),
    );
  }
}
```

**`lib/src/features/backup/presentation/verify_mnemonic_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerifyMnemonicScreen extends ConsumerWidget {
  const VerifyMnemonicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Mnemonic')),
      body: const Center(child: Text('Verify Mnemonic — TODO')),
    );
  }
}
```

**`lib/src/features/transfer/presentation/send_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SendScreen extends ConsumerWidget {
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: const Center(child: Text('Send — TODO')),
    );
  }
}
```

**`lib/src/features/transfer/presentation/confirm_transaction_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmTransactionScreen extends ConsumerWidget {
  const ConfirmTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Transaction')),
      body: const Center(child: Text('Confirm Transaction — TODO')),
    );
  }
}
```

**`lib/src/features/transfer/presentation/receive_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: const Center(child: Text('Receive — TODO')),
    );
  }
}
```

**`lib/src/features/history/presentation/history_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: const Center(child: Text('Transaction History — TODO')),
    );
  }
}
```

**`lib/src/features/settings/presentation/settings_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings — TODO')),
    );
  }
}
```

**`lib/src/features/network/presentation/network_management_screen.dart`**:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkManagementScreen extends ConsumerWidget {
  const NetworkManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Management')),
      body: const Center(child: Text('Network Management — TODO')),
    );
  }
}
```

**Step 3: Add .gitkeep for empty layer directories**

```bash
# Add .gitkeep to directories that have no files yet
for dir in \
  lib/src/features/wallet/domain \
  lib/src/features/wallet/data \
  lib/src/features/wallet/application \
  lib/src/features/wallet/presentation/widgets \
  lib/src/features/auth/domain \
  lib/src/features/auth/data \
  lib/src/features/auth/application \
  lib/src/features/backup/domain \
  lib/src/features/backup/application \
  lib/src/features/transfer/domain \
  lib/src/features/transfer/data \
  lib/src/features/transfer/application \
  lib/src/features/history/domain \
  lib/src/features/history/data \
  lib/src/features/network/domain \
  lib/src/features/network/data \
  lib/src/features/settings/domain \
  lib/src/features/settings/data; do
  touch "$dir/.gitkeep"
done
```

**Step 4: Commit**

```bash
git add lib/src/features/
git commit -m "feat(features): add all feature module directories with placeholder screens"
```

---

## Task 8: main.dart + app.dart — app entry point

**Files:**
- Modify: `lib/main.dart` (replace flutter create default)
- Create: `lib/app.dart`

**Step 1: Write main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize flutter_rust_bridge when FRB codegen is run
  // await RustLib.init();

  runApp(const ProviderScope(child: UnVaultApp()));
}
```

**Step 2: Write app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/routing/app_router.dart';
import 'src/localization/generated/app_localizations.dart';

class UnVaultApp extends ConsumerWidget {
  const UnVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'UnVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
```

**Step 3: Run flutter analyze**

```bash
flutter analyze
```

Note: This will likely show errors because `app_router.g.dart` and `app_providers.g.dart` don't exist yet. These are generated files. We handle this in Task 9.

**Step 4: Commit**

```bash
git add lib/main.dart lib/app.dart
git commit -m "feat(app): add main.dart entry point and UnVaultApp with routing and l10n"
```

---

## Task 9: Run code generation and verify

**Step 1: Run build_runner for generated code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- `lib/src/routing/app_router.g.dart` (riverpod_generator)
- `lib/src/core/providers/app_providers.g.dart` (riverpod_generator)
- `lib/src/core/database/app_database.g.dart` (drift_dev)

**Step 2: Verify flutter analyze passes**

```bash
flutter analyze
```

Expected: No errors.

**Step 3: Commit generated code**

```bash
git add lib/src/**/*.g.dart
git commit -m "chore(codegen): add generated code from build_runner (riverpod, drift)"
```

---

## Task 10: Test directory scaffold

**Files:**
- Create: `test/helpers/pump_app.dart`
- Create: `test/mocks/mocks.dart`
- Create: `test/unit/.gitkeep`
- Create: `test/widget/.gitkeep`
- Create: `test/golden/.gitkeep`
- Create: `test/fixtures/.gitkeep`
- Create: `integration_test/.gitkeep`

**Step 1: Create test directories**

```bash
mkdir -p test/{helpers,mocks,unit,widget,golden,fixtures}
mkdir -p integration_test
```

**Step 2: Write test/helpers/pump_app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(home: widget),
      ),
    );
  }
}
```

**Step 3: Write test/mocks/mocks.dart**

```dart
// Barrel file for mock classes.
// Add mock implementations here as features are developed.
//
// Example:
// import 'package:mocktail/mocktail.dart';
// class MockAppDatabase extends Mock implements AppDatabase {}
```

**Step 4: Add .gitkeep for empty directories**

```bash
touch test/unit/.gitkeep
touch test/widget/.gitkeep
touch test/golden/.gitkeep
touch test/fixtures/.gitkeep
touch integration_test/.gitkeep
```

**Step 5: Run flutter test to verify**

```bash
flutter test
```

Expected: "No tests found." or similar — no errors.

**Step 6: Commit**

```bash
git add test/ integration_test/
git commit -m "test(scaffold): add test directory structure with helpers and mock barrel file"
```

---

## Task 11: Update tech spec document (以太坊钱包UnVault技术规范文档.md)

Update Section 2 (核心技术选型) and Section 5.5 (Flutter 依赖参考) with architect-reviewed versions, and add a changelog at the bottom.

**Files:**
- Modify: `以太坊钱包UnVault技术规范文档.md`

**Step 1: Update Section 5.5 (Flutter 依赖参考, lines ~500-515)**

Replace the old dependency block:

```yaml
dependencies:
  flutter_riverpod: ^2.x    # 状态管理
  drift: ^2.x               # 本地数据库 (SQLite)
  go_router: ^x.x           # 路由
  local_auth: ^2.x          # 生物识别
  flutter_secure_storage: ^9.x  # Keychain/Keystore 封装
  freezed_annotation: ^2.x  # 不可变数据模型（注解）

dev_dependencies:
  freezed: ^2.x             # 代码生成
  build_runner: ^2.x        # 构建工具
  drift_dev: ^2.x           # drift 代码生成
```

With the reviewed versions:

```yaml
dependencies:
  flutter_riverpod: ^3.0.0        # 状态管理 (Riverpod 3.x, auto-dispose 默认)
  riverpod_annotation: ^3.0.0     # Riverpod 代码生成注解
  go_router: ^14.8.0              # 路由
  freezed_annotation: ^3.0.0      # 不可变数据模型 (freezed 3.x, sealed class)
  json_annotation: ^4.9.0         # JSON 序列化注解
  drift: ^2.22.0                  # 本地数据库 (SQLite)
  drift_flutter: ^0.2.0           # drift SQLite 连接（替代 sqlite3_flutter_libs）
  flutter_secure_storage: ^9.2.0  # Keychain/Keystore 封装
  local_auth: ^2.3.0              # 生物识别
  flutter_rust_bridge: ^2.7.0     # Rust FFI 桥接
  path_provider: ^2.1.0           # 文件路径
  path: ^1.9.0                    # 路径工具

dev_dependencies:
  riverpod_generator: ^3.0.0      # Riverpod 代码生成
  riverpod_lint: ^3.0.0           # Riverpod 专用 lint 规则
  custom_lint: ^0.7.0             # 自定义 lint 框架
  freezed: ^3.0.0                 # freezed 代码生成
  json_serializable: ^6.9.0       # JSON 序列化代码生成
  build_runner: ^2.4.0            # 构建工具
  drift_dev: ^2.22.0              # drift 代码生成
  mocktail: ^1.0.0                # 测试 Mock（无需代码生成）
  very_good_analysis: ^7.0.0      # 严格 lint 规则集
```

**Step 2: Append changelog section at the end of the file**

After the last line of the document (after `## 16. 开发检查清单` section), append:

```markdown

## Changelog

### 2026-03-03

- **[Section 5.5]** 更新 Flutter 依赖版本：
  - Riverpod `^2.x` → `^3.0.0`（3.x 默认 auto-dispose，统一 Ref API）
  - freezed `^2.x` → `^3.0.0`（3.x 使用 sealed class，集合自动不可变）
  - 新增 `drift_flutter: ^0.2.0`（替代 `sqlite3_flutter_libs`，drift 官方推荐）
  - 新增 `riverpod_annotation: ^3.0.0` + `riverpod_generator: ^3.0.0`（代码生成方式）
  - 新增 `riverpod_lint: ^3.0.0` + `custom_lint: ^0.7.0`（Riverpod 专用 lint）
  - 新增 `very_good_analysis: ^7.0.0`（替代 `flutter_lints`，更严格的 lint 规则）
  - 新增 `json_annotation` / `json_serializable`（freezed 3.x 依赖）
  - 新增 `flutter_rust_bridge: ^2.7.0`（明确 FFI 桥接版本）
  - 新增 `path_provider` / `path`（文件路径工具）
  - 新增 `mocktail: ^1.0.0`（测试 Mock 框架）
  - 来源：架构师 Review，确认所有依赖符合 2026 年 Flutter 生态最新实践
```

**Step 3: Commit**

```bash
git add "以太坊钱包UnVault技术规范文档.md"
git commit -m "docs(spec): update Flutter dependency versions per architect review

Update section 5.5 with Riverpod 3.x, freezed 3.x, drift_flutter,
riverpod_lint, very_good_analysis. Add changelog entry."
```

---

## Task 12: Create root README.md

**Files:**
- Create: `README.md`

**Step 1: Write README.md**

```markdown
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
| Storage | iOS Keychain / Android Keystore (sensitive), SQLite (metadata) |

## Project Structure

```
unvault/
├── rust/                    # Rust cryptographic core (132 tests)
│   └── src/
│       ├── api/             # FFI thin wrappers
│       ├── crypto/          # BIP-39, BIP-44, Argon2id, AES-256-GCM
│       ├── wallet/          # Wallet lifecycle management
│       ├── transaction/     # EIP-1559 tx building & signing
│       └── models/          # Shared types
├── lib/                     # Flutter UI
│   ├── main.dart            # Entry point
│   ├── app.dart             # MaterialApp.router
│   └── src/
│       ├── features/        # Feature modules (7 features)
│       ├── core/            # Shared infrastructure
│       ├── routing/         # go_router configuration
│       └── localization/    # i18n (EN + ZH)
├── test/                    # Flutter tests
├── integration_test/        # E2E tests
├── android/                 # Android platform
└── ios/                     # iOS platform
```

## Getting Started

### Prerequisites

- Flutter 3.38+ (`flutter --version`)
- Rust 1.75+ (`rustc --version`)
- Xcode (iOS) / Android Studio (Android)

### Setup

```bash
# Install Flutter dependencies
flutter pub get

# Run Rust tests
cd rust && cargo test --all-targets && cd ..

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Launch app
flutter run
```

## Security Principles

1. **Signing in Rust only** — private keys never cross FFI boundary
2. **Bytes-only FFI** — `Vec<u8>`/`Uint8List` for all sensitive data, never String
3. **Zeroize everything** — all secrets cleared from memory immediately after use
4. **CSPRNG only** — `OsRng` for all cryptographic randomness
5. **Double protection** — Argon2id encryption + platform secure storage

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

## License

[TBD]
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add root README with architecture, setup, and security overview"
```

---

## Task 13: Final verification

**Step 1: Run full flutter analyze**

```bash
flutter analyze
```

Expected: No errors or warnings (except in generated files which are excluded).

**Step 2: Run flutter test**

```bash
flutter test
```

Expected: No test failures (no tests exist yet, should exit cleanly).

**Step 3: Verify git status is clean**

```bash
git status
```

Expected: Clean working tree.

**Step 4: Review commit log**

```bash
git log --oneline -10
```

Expected: ~8 new commits following conventional commit format.
