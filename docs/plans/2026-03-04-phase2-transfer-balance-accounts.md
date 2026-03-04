# Phase 2: Transfer, Balance, Accounts & Settings

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Implement the complete send/receive flow, live balance display, multi-wallet/account management, network switching, transaction history, and settings — turning the MVP into a usable wallet.

**Architecture:** Dart-side JSON-RPC client for blockchain queries (balance, gas, nonce, broadcast). Rust core handles signing only. TabBar navigation (Home/History/Settings) via go_router ShellRoute. Chain switching via Home header BottomSheet. Multi-wallet + multi-account via Accounts table + derive_accounts FFI.

**Tech Stack:** Flutter 3.38, Dart http (JSON-RPC), go_router ShellRoute, Riverpod 3, drift, flutter_rust_bridge v2, freezed, qr_flutter (QR codes)

---

## Current State Snapshot

- **Rust core:** 138 tests, complete crypto/wallet/transaction signing. `sign_transaction` accepts all EIP-1559 params.
- **Flutter MVP:** Auth + wallet create/import + backup done (12 tests). Stub screens for Send, Receive, Confirm, History, Settings, Network.
- **DB tables:** Wallets (used), Accounts/Transactions/Networks (schema only, no DAOs).
- **Routing:** Flat GoRoute, no TabBar. Routes for all screens exist but stubs.
- **Known debt:** `walletId=1` hardcoded in lock screen. Accounts table not populated on wallet creation.

---

## Task 1: Ethereum JSON-RPC Service

**Files:**
- Create: `lib/src/core/services/eth_rpc_service.dart`
- Test: `test/unit/core/services/eth_rpc_service_test.dart`

This service wraps `dart:io` HttpClient / `package:http` to call Ethereum JSON-RPC methods. All blockchain queries flow through this single service.

**Step 1: Add http dependency**

Check if `http` is already in pubspec.yaml. If not, add it:

```bash
flutter pub add http
```

**Step 2: Write EthRpcService**

```dart
// lib/src/core/services/eth_rpc_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class RpcException implements Exception {
  const RpcException(this.code, this.message);
  final int code;
  final String message;
  @override
  String toString() => 'RpcException($code): $message';
}

class EthRpcService {
  EthRpcService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  int _requestId = 0;

  /// Raw JSON-RPC call. Returns the 'result' field or throws [RpcException].
  Future<dynamic> call(String rpcUrl, String method, [List<dynamic> params = const []]) async {
    final id = ++_requestId;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    final response = await _client.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode != 200) {
      throw RpcException(-1, 'HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      throw RpcException(err['code'] as int, err['message'] as String);
    }
    return json['result'];
  }

  /// Returns balance in wei as BigInt.
  Future<BigInt> getBalance(String rpcUrl, String address) async {
    final hex = await call(rpcUrl, 'eth_getBalance', [address, 'latest']) as String;
    return BigInt.parse(hex);
  }

  /// Returns current nonce for address.
  Future<int> getTransactionCount(String rpcUrl, String address) async {
    final hex = await call(rpcUrl, 'eth_getTransactionCount', [address, 'latest']) as String;
    return int.parse(hex);
  }

  /// Returns gas estimate as int.
  Future<int> estimateGas(String rpcUrl, Map<String, dynamic> txObj) async {
    final hex = await call(rpcUrl, 'eth_estimateGas', [txObj]) as String;
    return int.parse(hex);
  }

  /// Returns (baseFeePerGas, maxPriorityFeePerGas) for EIP-1559 fee estimation.
  Future<({BigInt baseFee, BigInt priorityFee})> getEip1559Fees(String rpcUrl) async {
    final block = await call(rpcUrl, 'eth_getBlockByNumber', ['latest', false]) as Map<String, dynamic>;
    final baseFee = BigInt.parse(block['baseFeePerGas'] as String);

    final priorityHex = await call(rpcUrl, 'eth_maxPriorityFeePerGas') as String;
    final priorityFee = BigInt.parse(priorityHex);

    return (baseFee: baseFee, priorityFee: priorityFee);
  }

  /// Broadcasts signed raw transaction. Returns tx hash.
  Future<String> sendRawTransaction(String rpcUrl, String rawTxHex) async {
    return await call(rpcUrl, 'eth_sendRawTransaction', [rawTxHex]) as String;
  }

  /// Gets transaction receipt. Returns null if pending.
  Future<Map<String, dynamic>?> getTransactionReceipt(String rpcUrl, String txHash) async {
    final result = await call(rpcUrl, 'eth_getTransactionReceipt', [txHash]);
    return result as Map<String, dynamic>?;
  }

  void dispose() => _client.close();
}
```

**Step 3: Write unit tests with mock HTTP client**

Test `getBalance`, `getTransactionCount`, `estimateGas`, `getEip1559Fees`, `sendRawTransaction`, and error handling. Use `MockClient` from `package:http/testing.dart`.

```dart
// test/unit/core/services/eth_rpc_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/eth_rpc_service.dart';

void main() {
  late EthRpcService service;

  group('getBalance', () {
    test('parses hex balance to BigInt', () async {
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_getBalance');
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0xDE0B6B3A7640000'}),
          200,
        );
      });
      service = EthRpcService(client: mockClient);
      final balance = await service.getBalance('https://rpc.test', '0xabc');
      expect(balance, BigInt.parse('1000000000000000000')); // 1 ETH
    });
  });

  group('getTransactionCount', () {
    test('parses hex nonce', () async {
      final mockClient = MockClient((req) async => http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x5'}), 200,
      ));
      service = EthRpcService(client: mockClient);
      expect(await service.getTransactionCount('https://rpc.test', '0xabc'), 5);
    });
  });

  group('error handling', () {
    test('throws RpcException on JSON-RPC error', () async {
      final mockClient = MockClient((req) async => http.Response(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'error': {'code': -32000, 'message': 'nope'}}), 200,
      ));
      service = EthRpcService(client: mockClient);
      expect(
        () => service.getBalance('https://rpc.test', '0xabc'),
        throwsA(isA<RpcException>()),
      );
    });

    test('throws RpcException on HTTP error', () async {
      final mockClient = MockClient((req) async => http.Response('', 500));
      service = EthRpcService(client: mockClient);
      expect(
        () => service.getBalance('https://rpc.test', '0xabc'),
        throwsA(isA<RpcException>()),
      );
    });
  });
}
```

**Step 4: Run tests**

```bash
flutter test test/unit/core/services/eth_rpc_service_test.dart
```

Expected: All PASS.

**Step 5: Add Riverpod provider**

Add to `lib/src/core/providers/app_providers.dart`:

```dart
@Riverpod(keepAlive: true)
EthRpcService ethRpcService(Ref ref) => EthRpcService();
```

**Step 6: Commit**

```bash
git add lib/src/core/services/eth_rpc_service.dart test/unit/core/services/eth_rpc_service_test.dart lib/src/core/providers/app_providers.dart pubspec.yaml pubspec.lock
git commit -m "feat(rpc): add Ethereum JSON-RPC service with balance, nonce, gas, and broadcast"
```

---

## Task 2: Network DAO + Active Network State

**Files:**
- Create: `lib/src/core/database/daos/networks_dao.dart`
- Create: `lib/src/features/network/data/network_repository.dart`
- Create: `lib/src/features/network/application/network_notifier.dart`
- Modify: `lib/src/core/database/app_database.dart` (register NetworksDao)
- Test: `test/unit/features/network/data/network_repository_test.dart`

**Step 1: Create NetworksDao**

```dart
// lib/src/core/database/daos/networks_dao.dart
import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/networks_table.dart';

part 'networks_dao.g.dart';

@DriftAccessor(tables: [Networks])
class NetworksDao extends DatabaseAccessor<AppDatabase> with _$NetworksDaoMixin {
  NetworksDao(super.db);

  Future<List<Network>> getAllNetworks() => select(networks).get();

  Future<Network?> getByChainId(int chainId) =>
      (select(networks)..where((n) => n.chainId.equals(chainId))).getSingleOrNull();

  Future<void> upsertNetwork(NetworksCompanion network) =>
      into(networks).insertOnConflictUpdate(network);

  Future<void> deleteNetwork(int chainId) =>
      (delete(networks)..where((n) => n.chainId.equals(chainId))).go();

  Future<List<Network>> getCustomNetworks() =>
      (select(networks)..where((n) => n.isCustom.equals(true))).get();
}
```

**Step 2: Register in AppDatabase**

Add `NetworksDao` to `@DriftDatabase` annotation daos list and add getter.

**Step 3: Create NetworkRepository**

```dart
// lib/src/features/network/data/network_repository.dart
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/database/daos/networks_dao.dart';

class NetworkRepository {
  NetworkRepository(this._dao);
  final NetworksDao _dao;

  /// Seeds built-in chains on first launch.
  Future<void> seedBuiltInChains() async {
    for (final chain in BuiltInChains.all) {
      await _dao.upsertNetwork(NetworksCompanion.insert(
        chainId: Value(chain.chainId),
        name: chain.name,
        symbol: chain.symbol,
        decimals: Value(chain.decimals),
        rpcUrl: chain.rpcUrls.first,
        explorerUrl: chain.explorerUrl,
        gasType: Value(chain.gasType.name),
        isTestnet: Value(chain.isTestnet),
        isCustom: Value(false),
      ));
    }
  }

  Future<List<Network>> getAllNetworks() => _dao.getAllNetworks();
  Future<void> addCustomNetwork(NetworksCompanion n) => _dao.upsertNetwork(n);
  Future<void> removeCustomNetwork(int chainId) => _dao.deleteNetwork(chainId);
}
```

**Step 4: Create NetworkNotifier (active chain state)**

```dart
// lib/src/features/network/application/network_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/constants/chain_config.dart';

part 'network_notifier.g.dart';

@Riverpod(keepAlive: true)
class ActiveNetwork extends _$ActiveNetwork {
  @override
  ChainConfig build() => BuiltInChains.ethereumMainnet;

  void switchNetwork(ChainConfig chain) => state = chain;
}
```

This stores the currently selected chain. All balance/gas/send operations read from this provider to determine RPC URL and chain ID.

**Step 5: Write tests for NetworkRepository**

Test `seedBuiltInChains` populates all 8 chains. Test `addCustomNetwork` and `removeCustomNetwork`.

**Step 6: Run tests and commit**

```bash
flutter test test/unit/features/network/
git commit -m "feat(network): add NetworksDao, repository, and active network state"
```

---

## Task 3: Accounts DAO + Multi-Account Support

**Files:**
- Create: `lib/src/core/database/daos/accounts_dao.dart`
- Modify: `lib/src/core/database/app_database.dart` (register AccountsDao)
- Modify: `lib/src/features/wallet/data/wallet_repository.dart` (populate accounts on create/import)
- Create: `lib/src/features/wallet/application/active_wallet_notifier.dart`
- Test: `test/unit/core/database/daos/accounts_dao_test.dart`

**Step 1: Create AccountsDao**

```dart
// lib/src/core/database/daos/accounts_dao.dart
import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/accounts_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAccountsForWallet(int walletId) =>
      (select(accounts)..where((a) => a.walletId.equals(walletId))).get();

  Future<Account?> getAccount(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<int> countAccountsForWallet(int walletId) async {
    final result = await (selectOnly(accounts)
          ..addColumns([accounts.id.count()])
          ..where(accounts.walletId.equals(walletId)))
        .map((row) => row.read(accounts.id.count())!)
        .getSingle();
    return result;
  }
}
```

**Step 2: Register in AppDatabase**

Add `AccountsDao` to `@DriftDatabase` daos list and add getter.

**Step 3: Modify WalletRepository to populate Accounts on create/import**

After `createWallet` and `importWallet`, use `derive_accounts` FFI to get addresses and insert into Accounts table. Store at least the first account (index 0).

In `createWallet`:
```dart
// After inserting wallet row:
final walletId = await _dao.insertWallet(...);
// derive_accounts already gives firstAddress, insert as account:
await _accountsDao.insertAccount(AccountsCompanion.insert(
  walletId: walletId,
  derivationIndex: 0,
  address: response.firstAddress,
));
```

**Step 4: Create ActiveWalletNotifier**

```dart
// lib/src/features/wallet/application/active_wallet_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_wallet_notifier.g.dart';

/// Tracks the currently selected wallet ID and account ID.
@Riverpod(keepAlive: true)
class ActiveWallet extends _$ActiveWallet {
  @override
  ({int walletId, int accountId}) build() => (walletId: 0, accountId: 0);

  void setWallet(int walletId, int accountId) =>
      state = (walletId: walletId, accountId: accountId);

  void setAccount(int accountId) =>
      state = (walletId: state.walletId, accountId: accountId);
}
```

**Step 5: Fix hardcoded walletId=1 in LockScreen**

Replace hardcoded `walletId: 1` with the first wallet from walletList. After successful unlock, set `ActiveWallet` to the first wallet and its first account.

**Step 6: Add "derive new account" function to WalletRepository**

```dart
Future<Account> deriveNextAccount(int walletId, Uint8List passwordBytes) async {
  // 1. Read wallet credentials from secure storage
  // 2. Decrypt mnemonic using Rust FFI
  // 3. Count existing accounts for wallet
  // 4. derive_accounts(mnemonicBytes, nextIndex + 1) to get new address
  // 5. Insert into Accounts table
  // 6. Return the new Account
}
```

**Step 7: Write tests and commit**

```bash
flutter test test/unit/core/database/daos/accounts_dao_test.dart
git commit -m "feat(accounts): add AccountsDao, populate accounts on wallet creation, active wallet state"
```

---

## Task 4: TabBar Navigation (ShellRoute)

**Files:**
- Create: `lib/src/routing/scaffold_with_nav_bar.dart`
- Modify: `lib/src/routing/app_router.dart`
- Modify: `lib/src/routing/route_names.dart` (add `home` alias)

**Step 1: Create ScaffoldWithNavBar widget**

This wraps the 3 main tabs: Home (wallet), History, Settings. Uses `BottomNavigationBar` matching the prototype's dark theme (Wallet icon, History icon, Settings icon).

```dart
// lib/src/routing/scaffold_with_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

**Step 2: Refactor app_router.dart**

Replace flat routes for `/wallets`, `/history`, `/settings` with a `StatefulShellRoute.indexedStack`:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      ScaffoldWithNavBar(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/wallets',
        name: RouteNames.walletList,
        builder: (context, state) => const HomeScreen(), // renamed from WalletListScreen
        routes: [
          // create, import sub-routes...
        ],
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/history',
        name: RouteNames.history,
        builder: (context, state) => const HistoryScreen(),
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(path: 'network', name: RouteNames.networkManagement, ...),
        ],
      ),
    ]),
  ],
),
```

Transfer routes (`/transfer/send`, `/transfer/confirm`, `/transfer/receive`) and backup routes stay outside the ShellRoute as full-screen overlays.

**Step 3: Add transaction result route**

Add a new route for the Tx Result screen (prototype 10):

```dart
// Add to route_names.dart:
static const transactionResult = 'transaction-result';

// Add route:
GoRoute(
  path: '/transfer/result',
  name: RouteNames.transactionResult,
  builder: (context, state) {
    final extra = state.extra! as Map<String, dynamic>;
    return TransactionResultScreen(
      txHash: extra['txHash'] as String,
      amount: extra['amount'] as String,
      token: extra['token'] as String,
    );
  },
),
```

**Step 4: Verify existing tests still pass**

```bash
flutter test
flutter analyze
```

**Step 5: Commit**

```bash
git commit -m "feat(routing): add TabBar navigation with ShellRoute for Home/History/Settings"
```

---

## Task 5: Home Screen (Balance + Assets)

**Files:**
- Rewrite: `lib/src/features/wallet/presentation/wallet_list_screen.dart` → rename concept to "HomeScreen"
- Create: `lib/src/features/wallet/application/balance_notifier.dart`
- Create: `lib/src/features/wallet/domain/balance_model.dart`

This is the prototype's screen 06 — shows wallet name, total balance, action buttons (Send/Receive/Buy), and asset list per chain.

**Step 1: Create BalanceModel**

```dart
// lib/src/features/wallet/domain/balance_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_model.freezed.dart';

@freezed
abstract class TokenBalance with _$TokenBalance {
  const factory TokenBalance({
    required String symbol,
    required String chainName,
    required int chainId,
    required BigInt balanceWei,
    required int decimals,
  }) = _TokenBalance;
}
```

**Step 2: Create BalanceNotifier**

Fetches balances for the active account across all enabled networks:

```dart
// lib/src/features/wallet/application/balance_notifier.dart
@riverpod
Future<List<TokenBalance>> accountBalances(Ref ref) async {
  final activeWallet = ref.watch(activeWalletProvider);
  final rpc = ref.watch(ethRpcServiceProvider);
  // Get account address from DB
  // For each network in BuiltInChains.all:
  //   call rpc.getBalance(chain.rpcUrls.first, address)
  //   create TokenBalance
  // Return list
}
```

**Step 3: Rewrite WalletListScreen as HomeScreen**

Match prototype 06:
- Header: wallet name selector + chain badge + scan icon
- Balance section: total balance in USD (placeholder conversion), change indicator
- Action buttons: Send, Receive, Buy (Buy = placeholder/disabled)
- Asset list: per-chain balances with icon, name, balance, USD value

**Step 4: Wire action buttons**

- Send → `context.pushNamed(RouteNames.send)`
- Receive → `context.pushNamed(RouteNames.receive)`
- Chain badge tap → show chain switch BottomSheet (Task 6)

**Step 5: Run tests and commit**

```bash
flutter test
git commit -m "feat(home): implement home screen with balance display and asset list"
```

---

## Task 6: Chain Switch BottomSheet

**Files:**
- Create: `lib/src/features/network/presentation/chain_switch_sheet.dart`
- Modify: `lib/src/features/wallet/presentation/wallet_list_screen.dart` (wire chain badge tap)

Matches prototype 12 — bottom sheet with list of chains, checkmark on active, "Add Custom RPC" at bottom.

**Step 1: Create ChainSwitchSheet widget**

```dart
// lib/src/features/network/presentation/chain_switch_sheet.dart
class ChainSwitchSheet extends ConsumerWidget {
  // showModalBottomSheet content
  // List BuiltInChains.all with name, symbol, color icon
  // Checkmark on currently active network
  // On tap: ref.read(activeNetworkProvider.notifier).switchNetwork(chain)
  // "Add Custom RPC" row at bottom (navigate to network management)
}
```

**Step 2: Wire to Home screen header**

Tapping the chain badge (e.g., "ETH" pill) calls:
```dart
showModalBottomSheet(
  context: context,
  builder: (_) => const ChainSwitchSheet(),
);
```

**Step 3: Commit**

```bash
git commit -m "feat(network): add chain switch bottom sheet from home header"
```

---

## Task 7: Receive Screen

**Files:**
- Rewrite: `lib/src/features/transfer/presentation/receive_screen.dart`
- Add dependency: `flutter pub add qr_flutter`

Matches prototype 07 — QR code + address display + copy button.

**Step 1: Add qr_flutter dependency**

```bash
flutter pub add qr_flutter
```

**Step 2: Implement ReceiveScreen**

```dart
// Reads active account address from ActiveWallet + AccountsDao
// Displays QR code of address using QrImageView
// Address text with copy-to-clipboard button
// "Only send Ethereum (ERC-20) tokens to this address" note
// "Copy Address" primary button
```

**Step 3: Commit**

```bash
git commit -m "feat(receive): implement receive screen with QR code and address display"
```

---

## Task 8: Send Screen

**Files:**
- Rewrite: `lib/src/features/transfer/presentation/send_screen.dart`
- Create: `lib/src/features/transfer/application/send_notifier.dart`
- Create: `lib/src/features/transfer/domain/send_form_state.dart`

Matches prototype 08 — address input, amount with token selector, gas fee selector (Slow/Standard/Fast), "Review Transaction" button.

**Step 1: Create SendFormState**

```dart
@freezed
abstract class SendFormState with _$SendFormState {
  const factory SendFormState({
    @Default('') String toAddress,
    @Default('') String amount,
    @Default(GasTier.standard) GasTier gasTier,
    BigInt? estimatedGasWei,
    BigInt? baseFee,
    BigInt? priorityFee,
    String? error,
    @Default(false) bool isEstimating,
  }) = _SendFormState;
}

enum GasTier { slow, standard, fast }
```

**Step 2: Create SendNotifier**

```dart
@riverpod
class SendNotifier extends _$SendNotifier {
  @override
  SendFormState build() => const SendFormState();

  void setToAddress(String address) => state = state.copyWith(toAddress: address);
  void setAmount(String amount) => state = state.copyWith(amount: amount);
  void setGasTier(GasTier tier) => state = state.copyWith(gasTier: tier);

  Future<void> estimateGas() async {
    // Use ethRpcService.getEip1559Fees() + ethRpcService.estimateGas()
    // Calculate slow/standard/fast multipliers
    // Update state with gas estimates
  }

  /// Validates form, returns true if ready for confirmation.
  bool validate() {
    // Check address format (0x + 40 hex chars)
    // Check amount > 0 and <= balance
    // Check gas estimated
  }
}
```

**Step 3: Implement SendScreen UI**

Match prototype 08:
- "To Address" input field (placeholder: "0x... or ENS name")
- Amount section: amount input + token pill (ETH with chevron) + fiat equivalent + MAX button
- Gas fee section: 3 option boxes (Slow $0.50 / Standard $1.20 / Fast $2.50) — values from RPC
- "Review Transaction" primary button → navigates to confirm screen

**Step 4: Wire gas estimation**

On screen load and when amount changes, call `estimateGas()`. Show loading indicator while estimating.

**Step 5: Commit**

```bash
git commit -m "feat(send): implement send screen with address, amount, and gas tier selection"
```

---

## Task 9: Confirm Transaction Screen

**Files:**
- Rewrite: `lib/src/features/transfer/presentation/confirm_transaction_screen.dart`

Matches prototype 09 — amount display, detail rows (From, To, Network, Gas Fee, Total), warning for first-time address, "Confirm & Send" button.

**Step 1: Implement ConfirmTransactionScreen**

Receives transaction details via route extra. Displays:
- Large amount + fiat equivalent
- Detail card: From, To, Network, Gas Fee, Total
- "First time sending to this address" warning (if applicable — check against Transactions table)
- "Confirm & Send" button

**Step 2: Wire "Confirm & Send" action**

On tap:
1. Show loading overlay
2. Get nonce via `ethRpcService.getTransactionCount()`
3. Decrypt mnemonic → derive private key for active account index
4. Call `signTransaction` FFI with all params
5. Broadcast via `ethRpcService.sendRawTransaction()`
6. Save transaction to Transactions table
7. Navigate to TransactionResultScreen

**SECURITY NOTE:** Private key derivation happens in Rust. The flow:
```
decryptMnemonic(password, encrypted, salt, argon2Params) → mnemonicBytes
deriveSeed(mnemonicBytes, []) → seedBytes
// Need new Rust FFI function: signWithSeed(seed, derivationIndex, txParams)
```

**Step 3: Check if we need a new Rust FFI function**

Current `sign_transaction` takes `private_key: Vec<u8>` directly. But we need to derive the private key from seed + derivation path first. Two options:

**Option A:** Add `sign_transaction_with_seed(seed, account_index, ...tx_params)` to Rust API — keeps private key entirely in Rust.
**Option B:** Add `derive_private_key(phrase_bytes, account_index) -> Vec<u8>` to Rust API — private key briefly crosses FFI but stays as bytes.

**Option A is more secure** (private key never leaves Rust). Add this function:

```rust
// In rust/src/api/transaction_api.rs
#[flutter_rust_bridge::frb]
pub fn sign_transaction_with_seed(
    phrase_bytes: Vec<u8>,
    account_index: u32,
    chain_id: u64,
    nonce: u64,
    to: String,
    value_wei: String,
    input: Vec<u8>,
    gas_limit: u64,
    max_fee_per_gas: u128,
    max_priority_fee_per_gas: u128,
) -> Result<SignTransactionResponse> {
    let seed = wallet::manager::derive_seed_from_phrase(&phrase_bytes)?;
    let account = wallet::manager::derive_account(&seed, account_index)?;
    let private_key = account.key_pair.expose_secret().private_key.to_vec();
    sign_transaction(private_key, chain_id, nonce, to, value_wei, input, gas_limit, max_fee_per_gas, max_priority_fee_per_gas)
}
```

After adding, regenerate FRB bindings:
```bash
flutter_rust_bridge_codegen generate
```

**Step 4: Commit**

```bash
git commit -m "feat(confirm): implement confirm transaction screen with signing and broadcast"
```

---

## Task 10: Transaction Result Screen

**Files:**
- Create: `lib/src/features/transfer/presentation/transaction_result_screen.dart`

Matches prototype 10 — success icon, "Transaction Sent!" title, tx hash with explorer link, "Back to Wallet" button.

**Step 1: Implement TransactionResultScreen**

```dart
class TransactionResultScreen extends ConsumerWidget {
  const TransactionResultScreen({
    required this.txHash,
    required this.amount,
    required this.token,
    super.key,
  });
  final String txHash;
  final String amount;
  final String token;

  // Success checkmark icon in green circle
  // "Transaction Sent!" title
  // Description text
  // Tx hash row with external-link icon → launch explorer URL
  // "Back to Wallet" button → goNamed(RouteNames.walletList)
}
```

**Step 2: Commit**

```bash
git commit -m "feat(transfer): add transaction result screen"
```

---

## Task 11: Transactions DAO + History Screen

**Files:**
- Create: `lib/src/core/database/daos/transactions_dao.dart`
- Modify: `lib/src/core/database/app_database.dart` (register TransactionsDao)
- Create: `lib/src/features/history/data/history_repository.dart`
- Create: `lib/src/features/history/application/history_notifier.dart`
- Rewrite: `lib/src/features/history/presentation/history_screen.dart`
- Test: `test/unit/features/history/data/history_repository_test.dart`

Matches prototype 11 — grouped by date, each tx shows send/receive icon, address, amount, fiat value.

**Step 1: Create TransactionsDao**

```dart
// lib/src/core/database/daos/transactions_dao.dart
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase> with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getTransactionsForAddress(String address) =>
      (select(transactions)
        ..where((t) => t.fromAddress.equals(address) | t.toAddress.equals(address))
        ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
      .get();

  Future<void> upsertTransaction(TransactionsCompanion tx) =>
      into(transactions).insertOnConflictUpdate(tx);

  Future<bool> hasTransactionWith(String address) async {
    final count = await (selectOnly(transactions)
      ..addColumns([transactions.hash.count()])
      ..where(transactions.toAddress.equals(address)))
      .map((row) => row.read(transactions.hash.count())!)
      .getSingle();
    return count > 0;
  }
}
```

**Step 2: Create HistoryRepository + Notifier**

Reads from local DB. Groups transactions by date for display.

**Step 3: Implement HistoryScreen**

Match prototype 11:
- Date section headers ("Today", "Yesterday", "Mar 1")
- Transaction rows: send icon (arrow-up-right, red bg) or receive icon (arrow-down-left, green bg)
- Address (truncated), amount in ETH, fiat value
- Pull-to-refresh

**Step 4: Run tests and commit**

```bash
git commit -m "feat(history): add TransactionsDao, repository, and history screen"
```

---

## Task 12: Accounts Screen (Multi-Wallet + Multi-Account)

**Files:**
- Create: `lib/src/features/wallet/presentation/accounts_screen.dart`
- Modify: `lib/src/routing/app_router.dart` (add route)
- Modify: Home screen header (wallet name tap → accounts screen)

Matches prototype 13 — lists all wallets with their accounts, "Active" badge on current, "Add Account" per wallet, "Create New Wallet" button.

**Step 1: Add accounts route**

```dart
// In route_names.dart:
static const accounts = 'accounts';

// In app_router.dart — inside the wallet ShellBranch:
GoRoute(
  path: 'accounts',
  name: RouteNames.accounts,
  builder: (context, state) => const AccountsScreen(),
),
```

**Step 2: Implement AccountsScreen**

Match prototype 13:
- For each wallet: card with wallet name, "Active" badge if selected, list of accounts (name + truncated address + balance)
- "Add Account" button per wallet (calls `walletRepository.deriveNextAccount()`)
- "Create New Wallet" outlined button at bottom
- Tap on account → set as active via `ActiveWallet.setWallet(walletId, accountId)`

**Step 3: Wire wallet name tap on Home screen**

Tapping the wallet name + chevron in Home header navigates to accounts screen.

**Step 4: Commit**

```bash
git commit -m "feat(accounts): implement accounts screen with multi-wallet and multi-account support"
```

---

## Task 13: Settings Screen

**Files:**
- Rewrite: `lib/src/features/settings/presentation/settings_screen.dart`

Matches prototype 14. Three sections:

**SECURITY:**
- Auto-Lock: shows current timeout (e.g., "30 sec") — taps to change
- Biometric Unlock: toggle switch
- Change Password: chevron → navigates to change password flow
- Backup Phrase: chevron → navigates to show mnemonic (requires password re-entry)

**GENERAL:**
- Network: shows current network name → navigates to network management
- Currency: shows "USD" → future feature (placeholder)
- Language: shows "English" → future feature (placeholder)

**ABOUT:**
- Version: shows app version
- Source Code: external link icon → opens GitHub

**Step 1: Implement SettingsScreen with grouped list**

Match prototype styling: section labels in uppercase with letter-spacing, cards with rows, appropriate icons, toggle for biometric, chevrons for drill-down rows.

**Step 2: Wire navigation**

- Change Password → new route (or reuse set-password with "change" mode)
- Backup Phrase → requires password entry, then show mnemonic
- Network → `context.pushNamed(RouteNames.networkManagement)`

**Step 3: Commit**

```bash
git commit -m "feat(settings): implement settings screen with security, general, and about sections"
```

---

## Task 14: Network Management Screen

**Files:**
- Rewrite: `lib/src/features/network/presentation/network_management_screen.dart`

Full-page network management (vs. the quick-switch BottomSheet in Task 6). Shows all networks with RPC URL, allows adding/removing custom RPCs.

**Step 1: Implement NetworkManagementScreen**

- List all networks from NetworkRepository
- Built-in chains: non-deletable, show name + RPC URL
- Custom chains: deletable with swipe or delete button
- "Add Custom RPC" → shows dialog/form for chainId, name, symbol, rpcUrl, explorerUrl

**Step 2: Commit**

```bash
git commit -m "feat(network): implement network management screen"
```

---

## Task 15: Rust API Addition — sign_transaction_with_seed

**Files:**
- Modify: `rust/src/api/transaction_api.rs`
- Regenerate: FRB bindings

This was identified in Task 9 as needed. If not done there, do it here.

**Step 1: Add function to Rust API**

```rust
#[flutter_rust_bridge::frb]
pub fn sign_transaction_with_seed(
    phrase_bytes: Vec<u8>,
    account_index: u32,
    chain_id: u64,
    nonce: u64,
    to: String,
    value_wei: String,
    input: Vec<u8>,
    gas_limit: u64,
    max_fee_per_gas: u128,
    max_priority_fee_per_gas: u128,
) -> Result<SignTransactionResponse> {
    // 1. Derive seed from phrase
    // 2. Derive account at index
    // 3. Sign with private key
    // 4. Private key never leaves Rust, zeroized on drop
}
```

**Step 2: Add Rust tests**

```rust
#[test]
fn test_sign_transaction_with_seed() {
    let phrase = b"abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    let result = sign_transaction_with_seed(
        phrase.to_vec(), 0, 1, 0,
        "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045".to_string(),
        "1000000000000000000".to_string(),
        vec![], 21000, 30_000_000_000, 2_000_000_000,
    ).unwrap();
    assert!(!result.raw_tx.is_empty());
    assert_eq!(result.tx_hash.len(), 32);
}
```

**Step 3: Run Rust tests**

```bash
cargo test --manifest-path rust/Cargo.toml --all-targets
```

**Step 4: Regenerate FRB bindings**

```bash
flutter_rust_bridge_codegen generate
```

**Step 5: Commit**

```bash
git commit -m "feat(transaction): add sign_transaction_with_seed to keep private key in Rust"
```

---

## Task 16: Integration Test — Full Send Flow

**Files:**
- Create: `integration_test/send_flow_test.dart`

**Step 1: Write integration test**

Test the complete send flow:
1. Create wallet via FFI
2. Get balance (mock or testnet)
3. Estimate gas
4. Sign transaction with seed
5. Verify signed tx is valid RLP

Note: actual broadcast requires testnet setup, so test up to signing.

**Step 2: Run integration test**

```bash
flutter test integration_test/send_flow_test.dart
```

**Step 3: Commit**

```bash
git commit -m "test(integration): add full send flow integration test"
```

---

## Task 17: Final Verification

**Step 1: Run all Rust tests**

```bash
cargo test --manifest-path rust/Cargo.toml --all-targets
```

Expected: All PASS (138 + new tests).

**Step 2: Run all Flutter tests**

```bash
flutter test
```

Expected: All PASS.

**Step 3: Run flutter analyze**

```bash
flutter analyze
```

Expected: No issues found.

**Step 4: Run clippy**

```bash
cargo clippy --manifest-path rust/Cargo.toml --all-targets -- -D warnings
```

Expected: No warnings.

**Step 5: Final commit if needed**

```bash
git commit -m "feat: Phase 2 complete — transfer, balance, accounts, settings, history"
```

---

## Implementation Notes

### Security Considerations
- `sign_transaction_with_seed` keeps private key entirely in Rust — never crosses FFI boundary
- Password bytes for mnemonic decryption should be collected via secure input and zeroized after use
- RPC URLs from user input should be validated (HTTPS only for mainnet)
- Transaction amounts should be validated against balance before signing

### What Comes After Phase 2
After these 17 tasks, the app supports:
- Multi-wallet with multiple derived accounts per wallet
- Balance display across all configured networks
- Send/Receive ETH on any EIP-1559 chain
- Transaction history
- Network switching + custom RPC management
- Settings with auto-lock, biometric toggle, change password, backup phrase

**Phase 3 backlog (next plan):**
1. ERC-20 token support (balance, transfer, token list management)
2. Biometric unlock implementation (local_auth integration)
3. Price feed integration (CoinGecko/similar for USD conversion)
4. ENS name resolution
5. WalletConnect v2 support
6. Auto-lock timer implementation
7. Transaction status polling (pending → confirmed)
