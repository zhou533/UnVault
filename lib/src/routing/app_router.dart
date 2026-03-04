
import 'dart:typed_data';

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/auth/presentation/biometric_setup_screen.dart';
import 'package:unvault/src/features/auth/presentation/lock_screen.dart';
import 'package:unvault/src/features/auth/presentation/set_password_screen.dart';
import 'package:unvault/src/features/backup/presentation/show_mnemonic_screen.dart';
import 'package:unvault/src/features/backup/presentation/verify_mnemonic_screen.dart';
import 'package:unvault/src/features/history/presentation/history_screen.dart';
import 'package:unvault/src/features/network/presentation/network_management_screen.dart';
import 'package:unvault/src/features/settings/presentation/settings_screen.dart';
import 'package:unvault/src/features/transfer/presentation/confirm_transaction_screen.dart';
import 'package:unvault/src/features/transfer/presentation/receive_screen.dart';
import 'package:unvault/src/features/transfer/presentation/send_screen.dart';
import 'package:unvault/src/features/transfer/presentation/transaction_result_screen.dart';
import 'package:unvault/src/features/wallet/presentation/create_wallet_screen.dart';
import 'package:unvault/src/features/wallet/presentation/import_wallet_screen.dart';
import 'package:unvault/src/features/wallet/presentation/wallet_list_screen.dart';
import 'package:unvault/src/routing/route_names.dart';
import 'package:unvault/src/routing/scaffold_with_nav_bar.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/lock',
    redirect: (context, routerState) {
      final location = routerState.matchedLocation;
      return authState.maybeWhen(
        loading: () => null,
        firstLaunch: () =>
            location != '/set-password' ? '/set-password' : null,
        unlocked: () {
          if (location == '/lock' || location == '/set-password') {
            return '/wallets';
          }
          return null;
        },
        orElse: () {
          const protectedPaths = [
            '/wallets',
            '/history',
            '/settings',
            '/transfer',
          ];
          if (protectedPaths.any(location.startsWith)) {
            return '/lock';
          }
          return null;
        },
      );
    },
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
      // Tabbed navigation: Wallet / History / Settings
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallets',
                name: RouteNames.walletList,
                builder: (context, state) => const WalletListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: RouteNames.createWallet,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final password = extra?['password'] as String? ?? '';
                      return CreateWalletScreen(
                        passwordBytes: password.codeUnits,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'import',
                    name: RouteNames.importWallet,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final password = extra?['password'] as String? ?? '';
                      return ImportWalletScreen(
                        passwordBytes: password.codeUnits,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: RouteNames.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'network',
                    name: RouteNames.networkManagement,
                    builder: (context, state) =>
                        const NetworkManagementScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen overlays (outside shell)
      GoRoute(
        path: '/backup/show',
        name: RouteNames.backupShow,
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return ShowMnemonicScreen(
            walletId: extra['walletId'] as int,
            mnemonicBytes: extra['mnemonicBytes'] as Uint8List,
          );
        },
      ),
      GoRoute(
        path: '/backup/verify',
        name: RouteNames.backupVerify,
        builder: (context, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return VerifyMnemonicScreen(
            walletId: extra['walletId'] as int,
            words: (extra['words'] as List).cast<String>(),
          );
        },
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
    ],
  );
}
