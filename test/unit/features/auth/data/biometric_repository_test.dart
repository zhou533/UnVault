import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/data/biometric_repository.dart';

class MockBiometricAdapter extends Mock implements BiometricAdapter {}

void main() {
  late MockBiometricAdapter mockAdapter;
  late BiometricRepository repo;

  setUp(() {
    mockAdapter = MockBiometricAdapter();
    repo = BiometricRepository(adapter: mockAdapter);
  });

  group('checkCapability', () {
    test('returns available when device supports biometrics', () async {
      when(() => mockAdapter.canCheckBiometrics())
          .thenAnswer((_) async => true);
      when(() => mockAdapter.isDeviceSupported())
          .thenAnswer((_) async => true);

      final capability = await repo.checkCapability();

      expect(capability, BiometricCapability.available);
    });

    test('returns unavailable when device does not support', () async {
      when(() => mockAdapter.canCheckBiometrics())
          .thenAnswer((_) async => false);
      when(() => mockAdapter.isDeviceSupported())
          .thenAnswer((_) async => false);

      final capability = await repo.checkCapability();

      expect(capability, BiometricCapability.unavailable);
    });

    test('returns notEnrolled when device supports but no biometrics enrolled',
        () async {
      when(() => mockAdapter.canCheckBiometrics())
          .thenAnswer((_) async => false);
      when(() => mockAdapter.isDeviceSupported())
          .thenAnswer((_) async => true);

      final capability = await repo.checkCapability();

      expect(capability, BiometricCapability.notEnrolled);
    });
  });

  group('isEnabled', () {
    test('returns true when biometric key exists for wallet', () async {
      when(() => mockAdapter.hasBiometricKey(walletId: 1))
          .thenAnswer((_) async => true);

      expect(await repo.isEnabled(walletId: 1), isTrue);
    });

    test('returns false when no biometric key for wallet', () async {
      when(() => mockAdapter.hasBiometricKey(walletId: 1))
          .thenAnswer((_) async => false);

      expect(await repo.isEnabled(walletId: 1), isFalse);
    });
  });

  group('authenticate', () {
    test('returns true on successful biometric authentication', () async {
      when(() => mockAdapter.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => true);

      expect(await repo.authenticate(), isTrue);
    });

    test('returns false on failed biometric authentication', () async {
      when(() => mockAdapter.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => false);

      expect(await repo.authenticate(), isFalse);
    });
  });

  group('enable/disable', () {
    test('enable stores biometric key for wallet', () async {
      when(() => mockAdapter.storeBiometricKey(walletId: 1))
          .thenAnswer((_) async {});

      await repo.enable(walletId: 1);

      verify(() => mockAdapter.storeBiometricKey(walletId: 1)).called(1);
    });

    test('disable removes biometric key for wallet', () async {
      when(() => mockAdapter.removeBiometricKey(walletId: 1))
          .thenAnswer((_) async {});

      await repo.disable(walletId: 1);

      verify(() => mockAdapter.removeBiometricKey(walletId: 1)).called(1);
    });
  });
}
