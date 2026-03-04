import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/history/domain/transaction_model.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';

part 'history_notifier.g.dart';

/// Provides the transaction history for the active account.
///
/// Returns an empty list when no account is selected or the account
/// cannot be found. Transactions are ordered by timestamp descending.
@riverpod
Future<List<TransactionModel>> transactionHistory(Ref ref) async {
  final activeWallet = ref.watch(activeWalletProvider);
  if (activeWallet.accountId == 0) return [];

  final db = ref.watch(appDatabaseProvider);

  // Look up the active account's address.
  final account = await db.accountsDao.getAccount(activeWallet.accountId);
  if (account == null) return [];

  final transactions =
      await db.transactionsDao.getTransactionsForAddress(account.address);

  return transactions
      .map(
        (tx) => TransactionModel(
          hash: tx.hash,
          fromAddress: tx.fromAddress,
          toAddress: tx.toAddress,
          value: tx.value,
          chainId: tx.chainId,
          status: tx.status,
          timestamp: tx.timestamp,
        ),
      )
      .toList();
}
