import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/biometric_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/data/biometric_repository.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

class MockBiometricRepository extends Mock implements BiometricRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBruteForceRepository extends Mock implements BruteForceRepository {}

void main() {
  late ProviderContainer container;
  late MockBiometricRepository mockBioRepo;
  late MockAuthRepository mockAuthRepo;
  late MockBruteForceRepository mockBfRepo;

  setUp(() {
    mockBioRepo = MockBiometricRepository();
    mockAuthRepo = MockAuthRepository();
    mockBfRepo = MockBruteForceRepository();

    when(() => mockBfRepo.getState())
        .thenAnswer((_) async => BruteForceState.initial);
    when(() => mockBfRepo.recordSuccess())
        .thenAnswer((_) async => BruteForceState.initial);

    container = ProviderContainer(
      overrides: [
        biometricRepositoryProvider.overrideWithValue(mockBioRepo),
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('BiometricNotifier', () {
    test('checkAvailability updates state', () async {
      when(() => mockBioRepo.checkCapability())
          .thenAnswer((_) async => BiometricCapability.available);
      when(() => mockBioRepo.isEnabled(walletId: 1))
          .thenAnswer((_) async => true);

      await container
          .read(biometricProvider.notifier)
          .checkAvailability(walletId: 1);

      final state = container.read(biometricProvider);
      expect(state.capability, BiometricCapability.available);
      expect(state.isEnabled, isTrue);
    });

    test('consecutive biometric failures tracked', () async {
      when(() => mockBioRepo.authenticate()).thenAnswer((_) async => false);

      final notifier = container.read(biometricProvider.notifier);
      await notifier.attemptBiometricUnlock(walletId: 1);
      await notifier.attemptBiometricUnlock(walletId: 1);
      await notifier.attemptBiometricUnlock(walletId: 1);

      expect(container.read(biometricProvider).consecutiveFailures, 3);
      expect(container.read(biometricProvider).shouldFallbackToPassword, isTrue);
    });

    test('successful biometric resets failure count', () async {
      when(() => mockBioRepo.authenticate()).thenAnswer((_) async => true);
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => true);

      final notifier = container.read(biometricProvider.notifier);
      await notifier.attemptBiometricUnlock(walletId: 1);

      expect(container.read(biometricProvider).consecutiveFailures, 0);
      // Auth should be unlocked
      expect(container.read(authProvider), const AuthState.unlocked());
    });

    test('biometric failures do not count toward brute-force', () async {
      when(() => mockBioRepo.authenticate()).thenAnswer((_) async => false);

      final notifier = container.read(biometricProvider.notifier);
      await notifier.attemptBiometricUnlock(walletId: 1);

      verifyNever(() => mockBfRepo.recordFailure());
    });
  });
}
