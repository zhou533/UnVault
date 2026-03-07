import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';
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

    final bfState = ref.read(bruteForceProvider);
    if (bfState.isLockedOut) return;

    // NOTE: walletId=1 for MVP. Multi-wallet: read active wallet from DB.
    await ref.read(authProvider.notifier).unlock(
          walletId: 1,
          passwordBytes: password.codeUnits,
        );
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
    final bfState = ref.watch(bruteForceProvider);
    final errorMsg = state.maybeWhen(error: (msg) => msg, orElse: () => null);
    final isLockedOut = bfState.isLockedOut;

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
            if (isLockedOut)
              _LockoutBanner(lockoutUntil: bfState.lockoutUntil!),
            if (!isLockedOut && bfState.failedAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${bfState.remainingAttempts} attempts remaining',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                ),
              ),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              enabled: !isLockedOut,
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
              onSubmitted: isLockedOut ? null : (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isLockedOut ? null : _unlock,
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockoutBanner extends StatelessWidget {
  const _LockoutBanner({required this.lockoutUntil});

  final DateTime lockoutUntil;

  @override
  Widget build(BuildContext context) {
    final remaining = lockoutUntil.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_clock,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Too many failed attempts.\n'
                'Try again in $minutes:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
