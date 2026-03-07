import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

part 'brute_force_notifier.g.dart';

@Riverpod(keepAlive: true)
class BruteForce extends _$BruteForce {
  @override
  BruteForceState build() => BruteForceState.initial;

  Future<void> loadState() async {
    final repo = ref.read(bruteForceRepositoryProvider);
    state = await repo.getState();
  }

  Future<void> onFailure() async {
    final repo = ref.read(bruteForceRepositoryProvider);
    state = await repo.recordFailure();
  }

  Future<void> onSuccess() async {
    final repo = ref.read(bruteForceRepositoryProvider);
    state = await repo.recordSuccess();
  }
}

@Riverpod(keepAlive: true)
BruteForceRepository bruteForceRepository(Ref ref) {
  return BruteForceRepository(
    storage: const SecureStorageBruteForceAdapter(),
  );
}
