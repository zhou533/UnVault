import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
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

    final wallets = await ref.read(walletListProvider.future);
    if (wallets.isEmpty) return;
    final firstWallet = wallets.first;

    await ref.read(authProvider.notifier).unlock(
          walletId: firstWallet.id,
          passwordBytes: password.codeUnits,
        );

    // Set active wallet only after successful unlock
    final authState = ref.read(authProvider);
    final isUnlocked = authState.maybeWhen(
      unlocked: () => true,
      orElse: () => false,
    );
    if (!isUnlocked) return;

    final accounts = await ref
        .read(appDatabaseProvider)
        .accountsDao
        .getAccountsForWallet(firstWallet.id);
    if (accounts.isNotEmpty) {
      ref
          .read(activeWalletProvider.notifier)
          .setWallet(firstWallet.id, accounts.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        unlocked: () => context.goNamed(RouteNames.walletList),
        orElse: () {},
      );
    });

    final state = ref.watch(authProvider);
    final errorMsg = state.maybeWhen(error: (msg) => msg, orElse: () => null);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'UnVault',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: errorMsg,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
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
