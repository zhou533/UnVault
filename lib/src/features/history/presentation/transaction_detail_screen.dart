import 'package:flutter/material.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.record});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBadge(theme),
          const SizedBox(height: 24),
          _detailRow(theme, 'Tx Hash', record.txHash),
          _detailRow(theme, 'From', record.from),
          _detailRow(theme, 'To', record.to),
          _detailRow(theme, 'Value', '${record.value} wei'),
          _detailRow(theme, 'Nonce', '${record.nonce}'),
          _detailRow(theme, 'Chain ID', '${record.chainId}'),
          _detailRow(theme, 'Timestamp', record.timestamp.toIso8601String()),
          if (record.blockNumber != null)
            _detailRow(theme, 'Block', '${record.blockNumber}'),
          if (record.gasUsed != null)
            _detailRow(theme, 'Gas Used', '${record.gasUsed}'),
          if (record.gasPrice != null)
            _detailRow(theme, 'Gas Price', '${record.gasPrice} wei'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final (label, color) = switch (record.status) {
      TransactionStatus.confirmed => ('Confirmed', Colors.green),
      TransactionStatus.pending => ('Pending', Colors.orange),
      TransactionStatus.failed => ('Failed', Colors.red),
    };

    return Center(
      child: Chip(
        label: Text(label, style: TextStyle(color: color)),
        backgroundColor: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(
            color: theme.hintColor,
          )),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
