import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/history/application/history_notifier.dart';
import 'package:unvault/src/features/history/domain/transaction_model.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';

/// Screen that displays transaction history for the active account.
///
/// Transactions are grouped by date with section headers ("Today",
/// "Yesterday", or the formatted date). Each row shows a send/receive
/// icon, the counterparty address (truncated), the ETH amount, and the
/// status.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(transactionHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const _EmptyState();
          }
          return _TransactionList(transactions: transactions);
        },
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load transactions: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWallet = ref.watch(activeWalletProvider);
    final db = ref.watch(appDatabaseProvider);

    return FutureBuilder<Account?>(
      future: db.accountsDao.getAccount(activeWallet.accountId),
      builder: (context, snapshot) {
        final accountAddress = snapshot.data?.address ?? '';
        final grouped = _groupByDate(transactions);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionHistoryProvider);
          },
          child: ListView.builder(
            itemCount: _totalItemCount(grouped),
            itemBuilder: (context, index) {
              final item = _itemAtIndex(grouped, index);
              if (item is String) {
                return _DateHeader(label: item);
              }
              final tx = item! as TransactionModel;
              final isSend = tx.fromAddress.toLowerCase() ==
                  accountAddress.toLowerCase();
              return _TransactionTile(transaction: tx, isSend: isSend);
            },
          ),
        );
      },
    );
  }

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> txs,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final tx in txs) {
      final label = _dateLabel(tx.timestamp);
      grouped.putIfAbsent(label, () => []).add(tx);
    }
    return grouped;
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  int _totalItemCount(Map<String, List<TransactionModel>> grouped) {
    var count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length; // header + items
    }
    return count;
  }

  /// Returns either a [String] (date header) or a [TransactionModel].
  Object? _itemAtIndex(
    Map<String, List<TransactionModel>> grouped,
    int index,
  ) {
    var current = 0;
    for (final entry in grouped.entries) {
      if (current == index) return entry.key;
      current++;
      if (index < current + entry.value.length) {
        return entry.value[index - current];
      }
      current += entry.value.length;
    }
    return null;
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.isSend,
  });

  final TransactionModel transaction;
  final bool isSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = isSend ? transaction.toAddress : transaction.fromAddress;
    final truncated = _truncateAddress(address ?? 'Contract');

    return ListTile(
      leading: _TransactionIcon(isSend: isSend),
      title: Text(
        isSend ? 'Sent' : 'Received',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        truncated,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isSend ? "-" : "+"}${_formatValue(transaction.value)} ETH',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSend ? theme.colorScheme.error : Colors.green,
            ),
          ),
          Text(
            transaction.status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _statusColor(transaction.status, theme),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 4)}';
  }

  String _formatValue(String weiValue) {
    final wei = BigInt.tryParse(weiValue);
    if (wei == null || wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(18);
    final whole = wei ~/ divisor;
    final remainder = wei.remainder(divisor).abs();
    final frac = remainder.toString().padLeft(18, '0').substring(0, 4);
    return '$whole.$frac';
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}

class _TransactionIcon extends StatelessWidget {
  const _TransactionIcon({required this.isSend});

  final bool isSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSend
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSend ? Icons.arrow_outward : Icons.arrow_downward,
        size: 20,
        color: isSend ? Colors.orange : Colors.green,
      ),
    );
  }
}
