import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

class MockSecureStorageAdapter extends Mock
    implements BruteForceStorageAdapter {}

void main() {
  late MockSecureStorageAdapter mockStorage;
  late BruteForceRepository repo;

  setUp(() {
    mockStorage = MockSecureStorageAdapter();
    repo = BruteForceRepository(storage: mockStorage);
  });

  group('getState', () {
    test('returns initial state when storage is empty', () async {
      when(() => mockStorage.readFailedAttempts()).thenAnswer((_) async => 0);
      when(() => mockStorage.readLockoutUntil()).thenAnswer((_) async => null);

      final state = await repo.getState();

      expect(state.failedAttempts, 0);
      expect(state.lockoutUntil, isNull);
    });

    test('returns persisted state', () async {
      final lockout = DateTime(2026, 3, 7, 12, 0);
      when(() => mockStorage.readFailedAttempts()).thenAnswer((_) async => 5);
      when(() => mockStorage.readLockoutUntil())
          .thenAnswer((_) async => lockout);

      final state = await repo.getState();

      expect(state.failedAttempts, 5);
      expect(state.lockoutUntil, lockout);
    });
  });

  group('recordFailure', () {
    test('increments failure count and persists', () async {
      when(() => mockStorage.readFailedAttempts()).thenAnswer((_) async => 2);
      when(() => mockStorage.readLockoutUntil()).thenAnswer((_) async => null);
      when(() => mockStorage.writeFailedAttempts(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.writeLockoutUntil(any()))
          .thenAnswer((_) async {});

      final state = await repo.recordFailure();

      expect(state.failedAttempts, 3);
      verify(() => mockStorage.writeFailedAttempts(3)).called(1);
    });

    test('sets 30 minute lockout on 10th failure', () async {
      when(() => mockStorage.readFailedAttempts()).thenAnswer((_) async => 9);
      when(() => mockStorage.readLockoutUntil()).thenAnswer((_) async => null);
      when(() => mockStorage.writeFailedAttempts(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.writeLockoutUntil(any()))
          .thenAnswer((_) async {});

      final state = await repo.recordFailure();

      expect(state.failedAttempts, 10);
      expect(state.lockoutUntil, isNotNull);
      verify(() => mockStorage.writeLockoutUntil(any())).called(1);
    });

    test('does not set lockout before 10th failure', () async {
      when(() => mockStorage.readFailedAttempts()).thenAnswer((_) async => 4);
      when(() => mockStorage.readLockoutUntil()).thenAnswer((_) async => null);
      when(() => mockStorage.writeFailedAttempts(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.writeLockoutUntil(any()))
          .thenAnswer((_) async {});

      final state = await repo.recordFailure();

      expect(state.failedAttempts, 5);
      expect(state.lockoutUntil, isNull);
      verify(() => mockStorage.writeLockoutUntil(null)).called(1);
    });
  });

  group('recordSuccess', () {
    test('resets failure count and lockout', () async {
      when(() => mockStorage.writeFailedAttempts(any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.writeLockoutUntil(any()))
          .thenAnswer((_) async {});

      final state = await repo.recordSuccess();

      expect(state, BruteForceState.initial);
      verify(() => mockStorage.writeFailedAttempts(0)).called(1);
      verify(() => mockStorage.writeLockoutUntil(null)).called(1);
    });
  });
}
