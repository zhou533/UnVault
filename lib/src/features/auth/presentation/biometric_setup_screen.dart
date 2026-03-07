import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/features/auth/application/biometric_notifier.dart';
import 'package:unvault/src/features/auth/data/biometric_repository.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key, required this.walletId});

  final int walletId;

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(biometricProvider.notifier)
          .checkAvailability(walletId: widget.walletId);
    });
  }

  Future<void> _toggle(bool enable) async {
    final notifier = ref.read(biometricProvider.notifier);
    if (enable) {
      await notifier.enable(walletId: widget.walletId);
    } else {
      await notifier.disable(walletId: widget.walletId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioState = ref.watch(biometricProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Unlock')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.fingerprint,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Use biometrics to unlock your wallet quickly and securely.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            if (bioState.capability == BiometricCapability.unavailable)
              _InfoCard(
                icon: Icons.warning_amber,
                color: theme.colorScheme.error,
                text:
                    'Biometric authentication is not available on this device.',
              )
            else if (bioState.capability == BiometricCapability.notEnrolled)
              _InfoCard(
                icon: Icons.info_outline,
                color: theme.colorScheme.tertiary,
                text:
                    'No biometrics enrolled. Please set up fingerprint or face recognition in device settings.',
              )
            else
              SwitchListTile(
                title: const Text('Enable Biometric Unlock'),
                subtitle: const Text(
                  'First app launch always requires password',
                ),
                value: bioState.isEnabled,
                onChanged: _toggle,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
