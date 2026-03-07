import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

/// Abstract adapter for brute-force state persistence.
/// Enables testing without depending directly on FlutterSecureStorage.
abstract class BruteForceStorageAdapter {
  Future<int> readFailedAttempts();
  Future<DateTime?> readLockoutUntil();
  Future<void> writeFailedAttempts(int count);
  Future<void> writeLockoutUntil(DateTime? lockout);
}

/// Production implementation backed by FlutterSecureStorage.
class SecureStorageBruteForceAdapter implements BruteForceStorageAdapter {
  const SecureStorageBruteForceAdapter({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _failedAttemptsKey = 'brute_force_failed_attempts';
  static const _lockoutUntilKey = 'brute_force_lockout_until';

  @override
  Future<int> readFailedAttempts() async {
    final value = await _storage.read(key: _failedAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  @override
  Future<DateTime?> readLockoutUntil() async {
    final value = await _storage.read(key: _lockoutUntilKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  @override
  Future<void> writeFailedAttempts(int count) async {
    await _storage.write(key: _failedAttemptsKey, value: count.toString());
  }

  @override
  Future<void> writeLockoutUntil(DateTime? lockout) async {
    if (lockout == null) {
      await _storage.delete(key: _lockoutUntilKey);
    } else {
      await _storage.write(
        key: _lockoutUntilKey,
        value: lockout.toIso8601String(),
      );
    }
  }
}

/// Manages brute-force protection state with persistence.
class BruteForceRepository {
  const BruteForceRepository({required BruteForceStorageAdapter storage})
      : _storage = storage;

  final BruteForceStorageAdapter _storage;

  static const _lockoutDuration = Duration(minutes: 30);

  Future<BruteForceState> getState() async {
    final attempts = await _storage.readFailedAttempts();
    final lockoutUntil = await _storage.readLockoutUntil();
    return BruteForceState(
      failedAttempts: attempts,
      lockoutUntil: lockoutUntil,
    );
  }

  Future<BruteForceState> recordFailure() async {
    final current = await getState();
    final newAttempts = current.failedAttempts + 1;
    final lockoutUntil =
        newAttempts >= 10 ? DateTime.now().add(_lockoutDuration) : null;

    await _storage.writeFailedAttempts(newAttempts);
    await _storage.writeLockoutUntil(lockoutUntil);

    return BruteForceState(
      failedAttempts: newAttempts,
      lockoutUntil: lockoutUntil,
    );
  }

  Future<BruteForceState> recordSuccess() async {
    await _storage.writeFailedAttempts(0);
    await _storage.writeLockoutUntil(null);
    return BruteForceState.initial;
  }
}
