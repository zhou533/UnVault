import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/application/sensitive_action_guard.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBruteForceRepository extends Mock implements BruteForceRepository {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockAuthRepo;
  late MockBruteForceRepository mockBfRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockBfRepo = MockBruteForceRepository();
    when(() => mockBfRepo.getState())
        .thenAnswer((_) async => BruteForceState.initial);
    when(() => mockBfRepo.recordSuccess())
        .thenAnswer((_) async => BruteForceState.initial);
    when(() => mockBfRepo.recordFailure()).thenAnswer(
      (_) async =>
          const BruteForceState(failedAttempts: 1, lockoutUntil: null),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('SensitiveActionGuard', () {
    test('verifyPassword returns true when password is correct', () async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => true);

      final guard = container.read(sensitiveActionGuardProvider);
      final result = await guard.verifyPassword(
        walletId: 1,
        passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
      );

      expect(result, isTrue);
      verify(() => mockBfRepo.recordSuccess()).called(1);
    });

    test('verifyPassword returns false and records failure on wrong password',
        () async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => false);

      final guard = container.read(sensitiveActionGuardProvider);
      final result = await guard.verifyPassword(
        walletId: 1,
        passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
      );

      expect(result, isFalse);
      verify(() => mockBfRepo.recordFailure()).called(1);
    });

    test('verifyPassword rejects when locked out', () async {
      // Set up locked-out state
      when(() => mockBfRepo.getState()).thenAnswer(
        (_) async => BruteForceState(
          failedAttempts: 10,
          lockoutUntil: DateTime.now().add(const Duration(minutes: 30)),
        ),
      );
      await container.read(bruteForceProvider.notifier).loadState();

      final guard = container.read(sensitiveActionGuardProvider);
      final result = await guard.verifyPassword(
        walletId: 1,
        passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
      );

      expect(result, isFalse);
      // Should not even attempt verification
      verifyNever(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      );
    });

    test('isSensitiveAction identifies sensitive actions correctly', () {
      final guard = container.read(sensitiveActionGuardProvider);
      expect(guard.isSensitiveAction('export_mnemonic'), isTrue);
      expect(guard.isSensitiveAction('large_transfer'), isTrue);
      expect(guard.isSensitiveAction('disable_biometric'), isTrue);
      expect(guard.isSensitiveAction('view_balance'), isFalse);
    });
  });
}
