import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';

part 'sensitive_action_guard.g.dart';

/// Actions requiring password confirmation before execution.
const sensitiveActions = {
  'export_mnemonic',
  'large_transfer',
  'disable_biometric',
};

/// Guards sensitive operations behind password re-confirmation.
///
/// Password confirmation failures count toward brute-force protection.
/// Biometric authentication cannot substitute for password confirmation.
class SensitiveActionGuard {
  const SensitiveActionGuard({
    required AuthRepository authRepo,
    required BruteForce bfNotifier,
    required BruteForceRepository bfRepo,
  })  : _authRepo = authRepo,
        _bfNotifier = bfNotifier,
        _bfRepo = bfRepo;

  final AuthRepository _authRepo;
  final BruteForce _bfNotifier;
  final BruteForceRepository _bfRepo;

  bool isSensitiveAction(String action) => sensitiveActions.contains(action);

  /// Verify password for a sensitive operation.
  /// Returns true if password is correct. Failures count toward brute-force.
  Future<bool> verifyPassword({
    required int walletId,
    required List<int> passwordBytes,
  }) async {
    final bfState = await _bfRepo.getState();
    if (bfState.isLockedOut) return false;

    final ok = await _authRepo.verifyPassword(
      walletId: walletId,
      passwordBytes: passwordBytes,
    );

    if (ok) {
      await _bfNotifier.onSuccess();
    } else {
      await _bfNotifier.onFailure();
    }

    return ok;
  }
}

@Riverpod(keepAlive: true)
SensitiveActionGuard sensitiveActionGuard(Ref ref) {
  return SensitiveActionGuard(
    authRepo: ref.watch(authRepositoryProvider),
    bfNotifier: ref.watch(bruteForceProvider.notifier),
    bfRepo: ref.watch(bruteForceRepositoryProvider),
  );
}
