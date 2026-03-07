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
  late MockAuthRepository mockRepo;
  late MockBruteForceRepository mockBfRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
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
        authRepositoryProvider.overrideWithValue(mockRepo),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is loading', () {
    final state = container.read(authProvider);
    expect(state, const AuthState.loading());
  });

  test('checkAuthState transitions to firstLaunch when no wallet', () async {
    when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => true);

    await container.read(authProvider.notifier).checkAuthState();

    expect(container.read(authProvider), const AuthState.firstLaunch());
  });

  test('checkAuthState transitions to locked when wallet exists', () async {
    when(() => mockRepo.isFirstLaunch()).thenAnswer((_) async => false);

    await container.read(authProvider.notifier).checkAuthState();

    expect(container.read(authProvider), const AuthState.locked());
  });

  test('unlock with correct password transitions to unlocked', () async {
    when(
      () => mockRepo.verifyPassword(
        walletId: any(named: 'walletId'),
        passwordBytes: any(named: 'passwordBytes'),
      ),
    ).thenAnswer((_) async => true);

    await container.read(authProvider.notifier).unlock(
          walletId: 1,
          passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
        );

    expect(container.read(authProvider), const AuthState.unlocked());
  });

  test('unlock with wrong password stays locked with error', () async {
    when(
      () => mockRepo.verifyPassword(
        walletId: any(named: 'walletId'),
        passwordBytes: any(named: 'passwordBytes'),
      ),
    ).thenAnswer((_) async => false);

    await container.read(authProvider.notifier).unlock(
          walletId: 1,
          passwordBytes: [1, 2, 3, 4, 5, 6, 7, 8],
        );

    expect(
      container.read(authProvider),
      const AuthState.error('Incorrect password'),
    );
  });
}
