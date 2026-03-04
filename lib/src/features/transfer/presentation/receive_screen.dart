import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';

/// Displays the active account's Ethereum address as a QR code
/// with a copy-to-clipboard action.
class ReceiveScreen extends ConsumerWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWallet = ref.watch(activeWalletProvider);
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: FutureBuilder<String>(
        future: activeWallet.accountId == 0
            ? Future<String>.value('')
            : db.accountsDao
                .getAccount(activeWallet.accountId)
                .then((account) => account?.address ?? ''),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }
          final address = snapshot.data!;
          if (address.isEmpty) {
            return const Center(
              child: Text('No account selected'),
            );
          }
          return _ReceiveContent(address: address);
        },
      ),
    );
  }
}

class _ReceiveContent extends StatelessWidget {
  const _ReceiveContent({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: address,
              size: 200,
            ),
          ),
          const SizedBox(height: 24),
          // Address display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyAddress(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Only send Ethereum (ERC-20) tokens to this address',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Copy Address button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _copyAddress(context),
              icon: const Icon(Icons.copy),
              label: const Text('Copy Address'),
            ),
          ),
        ],
      ),
    );
  }

  void _copyAddress(BuildContext context) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied')),
    );
  }
}
