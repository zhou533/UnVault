import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
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
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('BruteForceNotifier', () {
    test('loadState loads from repository', () async {
      when(() => mockBfRepo.getState())
          .thenAnswer((_) async => BruteForceState.initial);

      await container.read(bruteForceProvider.notifier).loadState();

      expect(
        container.read(bruteForceProvider),
        BruteForceState.initial,
      );
    });
  });

  group('AuthNotifier with brute-force', () {
    test('successful unlock resets brute-force state', () async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => true);
      when(() => mockBfRepo.getState())
          .thenAnswer((_) async => BruteForceState.initial);
      when(() => mockBfRepo.recordSuccess())
          .thenAnswer((_) async => BruteForceState.initial);

      await container.read(authProvider.notifier).unlock(
            walletId: 1,
            passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
          );

      expect(container.read(authProvider), const AuthState.unlocked());
      verify(() => mockBfRepo.recordSuccess()).called(1);
    });

    test('failed unlock records failure in brute-force state', () async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => false);
      when(() => mockBfRepo.getState())
          .thenAnswer((_) async => BruteForceState.initial);
      when(() => mockBfRepo.recordFailure()).thenAnswer(
        (_) async => const BruteForceState(
          failedAttempts: 1,
          lockoutUntil: null,
        ),
      );

      await container.read(authProvider.notifier).unlock(
            walletId: 1,
            passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
          );

      expect(
        container.read(authProvider),
        const AuthState.error('Incorrect password'),
      );
      verify(() => mockBfRepo.recordFailure()).called(1);
    });

    test('unlock blocked when locked out', () async {
      final lockout = DateTime.now().add(const Duration(minutes: 25));
      when(() => mockBfRepo.getState()).thenAnswer(
        (_) async => BruteForceState(
          failedAttempts: 10,
          lockoutUntil: lockout,
        ),
      );

      // Load locked-out state first (normally done during checkAuthState)
      await container.read(bruteForceProvider.notifier).loadState();

      await container.read(authProvider.notifier).unlock(
            walletId: 1,
            passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
          );

      // Should not attempt to verify password
      verifyNever(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      );
    });
  });
}
