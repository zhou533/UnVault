import 'package:flutter/services.dart';

/// Controls screenshot/screen recording protection via platform channels.
///
/// Android: Sets FLAG_SECURE on the window.
/// iOS: Monitors capturedDidChangeNotification for screen capture.
class ScreenSecurityService {
  const ScreenSecurityService();

  static const _channel = MethodChannel('com.unvault/screen_security');

  Future<void> enableProtection() async {
    await _channel.invokeMethod<void>('enableProtection');
  }

  Future<void> disableProtection() async {
    await _channel.invokeMethod<void>('disableProtection');
  }
}
