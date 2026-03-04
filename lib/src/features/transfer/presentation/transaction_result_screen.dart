import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

/// Displays the result of a successfully broadcast transaction.
///
/// Shows a success indicator, transaction amount, and a link to view the
/// transaction on a block explorer.
class TransactionResultScreen extends ConsumerWidget {
  const TransactionResultScreen({
    required this.txHash,
    required this.amount,
    required this.token,
    super.key,
  });

  /// Transaction hash as returned by `eth_sendRawTransaction` (0x-prefixed).
  final String txHash;

  /// Human-readable amount that was sent (e.g. "0.05").
  final String amount;

  /// Token symbol (e.g. "ETH").
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(activeNetworkProvider);
    final explorerUrl = '${network.explorerUrl}/tx/$txHash';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transaction Sent!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$amount $token sent successfully',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              // Tx hash display (truncated)
              _TxHashRow(txHash: txHash),
              const SizedBox(height: 16),
              // Explorer link — copies URL since url_launcher is not available.
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: explorerUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Explorer URL copied to clipboard'),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View on Explorer',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Back to wallet button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.goNamed(RouteNames.walletList),
                  child: const Text('Back to Wallet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays the transaction hash with copy-to-clipboard support.
class _TxHashRow extends StatelessWidget {
  const _TxHashRow({required this.txHash});

  final String txHash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final truncated = txHash.length > 20
        ? '${txHash.substring(0, 10)}...${txHash.substring(txHash.length - 8)}'
        : txHash;

    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: txHash));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction hash copied to clipboard'),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                truncated,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.copy,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
