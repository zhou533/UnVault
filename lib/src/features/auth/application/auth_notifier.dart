import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
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
    if (isFirst) {
      state = const AuthState.firstLaunch();
    } else {
      state = const AuthState.locked();
      await ref.read(bruteForceProvider.notifier).loadState();
    }
  }

  Future<void> unlock({
    required int walletId,
    required List<int> passwordBytes,
  }) async {
    final bfNotifier = ref.read(bruteForceProvider.notifier);
    final bfState = ref.read(bruteForceProvider);

    // Block unlock attempts when locked out
    if (bfState.isLockedOut) {
      state = const AuthState.error('Too many attempts. Please wait.');
      return;
    }

    final repo = ref.read(authRepositoryProvider);
    final ok = await repo.verifyPassword(
      walletId: walletId,
      passwordBytes: passwordBytes,
    );

    if (ok) {
      await bfNotifier.onSuccess();
      state = const AuthState.unlocked();
    } else {
      await bfNotifier.onFailure();
      state = const AuthState.error('Incorrect password');
    }
  }

  void lock() {
    state = const AuthState.locked();
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageServiceProvider),
  );
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  return const SecureStorageService();
}
