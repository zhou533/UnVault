import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
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
    final ok = await repo.verifyPassword(
      walletId: walletId,
      passwordBytes: passwordBytes,
    );
    state = ok ? const AuthState.unlocked() : const AuthState.error('Incorrect password');
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
