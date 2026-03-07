import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:unvault/src/core/services/device_security_service.dart';
import 'package:unvault/src/core/widgets/security_warning_dialog.dart';

const _dismissedKey = 'device_security_warning_dismissed';

/// Runs a one-time cold-start check for rooted/jailbroken devices.
/// Shows warning dialog if compromised and not previously dismissed.
class DeviceSecurityCheck {
  const DeviceSecurityCheck({
    DeviceSecurityService? deviceService,
    FlutterSecureStorage? storage,
  })  : _deviceService = deviceService ?? const DeviceSecurityService(),
        _storage = storage ?? const FlutterSecureStorage();

  final DeviceSecurityService _deviceService;
  final FlutterSecureStorage _storage;

  Future<void> runCheck(BuildContext context) async {
    final dismissed = await _storage.read(key: _dismissedKey);
    if (dismissed == 'true') return;

    final compromised = await _deviceService.isDeviceCompromised();
    if (!compromised) return;

    if (!context.mounted) return;

    final dontShowAgain = await showSecurityWarningDialog(context: context);
    if (dontShowAgain == true) {
      await _storage.write(key: _dismissedKey, value: 'true');
    }
  }
}
