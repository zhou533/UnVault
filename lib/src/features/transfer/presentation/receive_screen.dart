import 'package:flutter/material.dart';
import 'package:unvault/src/core/services/clipboard_security_service.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/qr_display.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({
    super.key,
    required this.address,
    required this.chainName,
    required this.symbol,
    this.clipboardService,
  });

  final String address;
  final String chainName;
  final String symbol;
  final ClipboardSecurityService? clipboardService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chainName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: QrDisplay(data: address),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Only send $symbol on the same network ($chainName)',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                address,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final service = clipboardService ?? ClipboardSecurityService();
                await service.secureCopy(address);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$chainName address copied (auto-clears in 60s)',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Address'),
            ),
          ],
        ),
      ),
    );
  }
}
