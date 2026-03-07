import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({
    super.key,
    required this.biometricEnabled,
    required this.biometricAvailable,
    required this.autoLockLabel,
    required this.onBiometricChanged,
    required this.onAutoLockTap,
    required this.onViewMnemonicTap,
  });

  final bool biometricEnabled;
  final bool biometricAvailable;
  final String autoLockLabel;
  final void Function(bool) onBiometricChanged;
  final VoidCallback onAutoLockTap;
  final VoidCallback onViewMnemonicTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Biometric Unlock'),
            subtitle: Text(
              biometricAvailable
                  ? 'Use fingerprint or face to unlock'
                  : 'Not available on this device',
            ),
            value: biometricEnabled,
            onChanged: biometricAvailable ? onBiometricChanged : null,
          ),
          ListTile(
            title: const Text('Auto-Lock Timer'),
            subtitle: Text(autoLockLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: onAutoLockTap,
          ),
          const Divider(),
          ListTile(
            title: const Text('View Recovery Phrase'),
            subtitle: const Text('Requires password verification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onViewMnemonicTap,
          ),
        ],
      ),
    );
  }
}
