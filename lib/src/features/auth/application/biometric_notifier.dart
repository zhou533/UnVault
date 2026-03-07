import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/biometric_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';

part 'biometric_notifier.g.dart';

class BiometricState {
  const BiometricState({
    this.capability = BiometricCapability.unavailable,
    this.isEnabled = false,
    this.consecutiveFailures = 0,
  });

  final BiometricCapability capability;
  final bool isEnabled;
  final int consecutiveFailures;

  static const maxConsecutiveFailures = 3;

  bool get shouldFallbackToPassword =>
      consecutiveFailures >= maxConsecutiveFailures;

  BiometricState copyWith({
    BiometricCapability? capability,
    bool? isEnabled,
    int? consecutiveFailures,
  }) =>
      BiometricState(
        capability: capability ?? this.capability,
        isEnabled: isEnabled ?? this.isEnabled,
        consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      );
}

@Riverpod(keepAlive: true)
class Biometric extends _$Biometric {
  @override
  BiometricState build() => const BiometricState();

  Future<void> checkAvailability({required int walletId}) async {
    final repo = ref.read(biometricRepositoryProvider);
    final capability = await repo.checkCapability();
    final enabled = await repo.isEnabled(walletId: walletId);
    state = state.copyWith(capability: capability, isEnabled: enabled);
  }

  Future<void> attemptBiometricUnlock({required int walletId}) async {
    final repo = ref.read(biometricRepositoryProvider);
    final ok = await repo.authenticate();

    if (ok) {
      state = state.copyWith(consecutiveFailures: 0);
      // Reset brute-force state on successful biometric
      await ref.read(bruteForceProvider.notifier).onSuccess();
      ref.read(authProvider.notifier).state = const AuthState.unlocked();
    } else {
      state = state.copyWith(
        consecutiveFailures: state.consecutiveFailures + 1,
      );
      // Biometric failures do NOT count toward brute-force
    }
  }

  Future<void> enable({required int walletId}) async {
    final repo = ref.read(biometricRepositoryProvider);
    await repo.enable(walletId: walletId);
    state = state.copyWith(isEnabled: true);
  }

  Future<void> disable({required int walletId}) async {
    final repo = ref.read(biometricRepositoryProvider);
    await repo.disable(walletId: walletId);
    state = state.copyWith(isEnabled: false);
  }
}

@Riverpod(keepAlive: true)
BiometricRepository biometricRepository(Ref ref) {
  return BiometricRepository(adapter: LocalAuthBiometricAdapter());
}
