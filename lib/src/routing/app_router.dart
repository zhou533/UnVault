
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import 'package:unvault/src/features/wallet/presentation/create_wallet_screen.dart';
import 'package:unvault/src/features/wallet/presentation/import_wallet_screen.dart';
import 'package:unvault/src/features/wallet/presentation/wallet_list_screen.dart';
import 'package:unvault/src/routing/route_names.dart';

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
