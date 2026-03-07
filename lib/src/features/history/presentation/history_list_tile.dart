import 'package:flutter/material.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

class HistoryListTile extends StatelessWidget {
  const HistoryListTile({
    super.key,
    required this.record,
    required this.myAddress,
    this.onTap,
  });

  final TransactionRecord record;
  final String myAddress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSent = record.isSent(myAddress);
    final isPending = record.status == TransactionStatus.pending;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isSent
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        child: Icon(
          isSent ? Icons.arrow_upward : Icons.arrow_downward,
          color: isSent ? Colors.red : Colors.green,
        ),
      ),
      title: Text(
        isSent ? 'Sent' : 'Received',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        isPending
            ? 'Pending'
            : _truncateAddress(isSent ? record.to : record.from),
        style: theme.textTheme.bodySmall?.copyWith(
          color: isPending ? Colors.orange : theme.hintColor,
        ),
      ),
      trailing: Text(
        '${isSent ? '-' : '+'}${_formatValue(record.value)}',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSent ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _truncateAddress(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  String _formatValue(BigInt weiValue) {
    final ethValue = weiValue / BigInt.from(10).pow(18);
    if (ethValue == BigInt.zero && weiValue > BigInt.zero) {
      return '<0.0001 ETH';
    }
    return '$ethValue ETH';
  }
}
