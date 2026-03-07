import 'package:flutter/services.dart';

/// Detects rooted (Android) or jailbroken (iOS) devices via native method channel.
/// Returns false on error (fail-safe: never block usage).
class DeviceSecurityService {
  const DeviceSecurityService();

  static const _channel = MethodChannel('com.unvault/device_security');

  Future<bool> isDeviceCompromised() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceCompromised');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
