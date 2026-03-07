import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.biometricEnabled,
    required this.autoLockLabel,
    required this.onBiometricToggle,
    required this.onAutoLockTap,
    required this.onViewMnemonicTap,
    required this.onNetworkManagementTap,
    required this.onAboutTap,
  });

  final bool biometricEnabled;
  final String autoLockLabel;
  final VoidCallback onBiometricToggle;
  final VoidCallback onAutoLockTap;
  final VoidCallback onViewMnemonicTap;
  final VoidCallback onNetworkManagementTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader(title: 'Security'),
          SwitchListTile(
            title: const Text('Biometric Unlock'),
            value: biometricEnabled,
            onChanged: (_) => onBiometricToggle(),
          ),
          ListTile(
            title: const Text('Auto-Lock'),
            trailing: Text(autoLockLabel),
            onTap: onAutoLockTap,
          ),
          ListTile(
            title: const Text('View Recovery Phrase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onViewMnemonicTap,
          ),
          const Divider(),
          _SectionHeader(title: 'Network'),
          ListTile(
            title: const Text('Network Management'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onNetworkManagementTap,
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('About UnVault'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onAboutTap,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
