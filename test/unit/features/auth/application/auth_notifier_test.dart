import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late ProviderContainer container;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
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
