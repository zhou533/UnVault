import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricCapability { available, notEnrolled, unavailable }

/// Abstract adapter for biometric operations.
/// Enables testing without depending directly on local_auth/secure storage.
abstract class BiometricAdapter {
  Future<bool> canCheckBiometrics();
  Future<bool> isDeviceSupported();
  Future<bool> authenticate({required String reason});
  Future<bool> hasBiometricKey({required int walletId});
  Future<void> storeBiometricKey({required int walletId});
  Future<void> removeBiometricKey({required int walletId});
}

/// Production implementation backed by local_auth + FlutterSecureStorage.
class LocalAuthBiometricAdapter implements BiometricAdapter {
  LocalAuthBiometricAdapter({
    LocalAuthentication? auth,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static String _biometricKey(int walletId) =>
      'wallet_${walletId}_biometric_enabled';

  @override
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> authenticate({required String reason}) {
    return _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );
  }

  @override
  Future<bool> hasBiometricKey({required int walletId}) async {
    final value = await _storage.read(key: _biometricKey(walletId));
    return value == 'true';
  }

  @override
  Future<void> storeBiometricKey({required int walletId}) async {
    await _storage.write(key: _biometricKey(walletId), value: 'true');
  }

  @override
  Future<void> removeBiometricKey({required int walletId}) async {
    await _storage.delete(key: _biometricKey(walletId));
  }
}

/// Manages biometric authentication with testable adapter.
class BiometricRepository {
  const BiometricRepository({required BiometricAdapter adapter})
      : _adapter = adapter;

  final BiometricAdapter _adapter;

  Future<BiometricCapability> checkCapability() async {
    final canCheck = await _adapter.canCheckBiometrics();
    final supported = await _adapter.isDeviceSupported();

    if (canCheck && supported) return BiometricCapability.available;
    if (supported) return BiometricCapability.notEnrolled;
    return BiometricCapability.unavailable;
  }

  Future<bool> isEnabled({required int walletId}) =>
      _adapter.hasBiometricKey(walletId: walletId);

  Future<bool> authenticate() =>
      _adapter.authenticate(reason: 'Unlock your wallet');

  Future<void> enable({required int walletId}) =>
      _adapter.storeBiometricKey(walletId: walletId);

  Future<void> disable({required int walletId}) =>
      _adapter.removeBiometricKey(walletId: walletId);
}
