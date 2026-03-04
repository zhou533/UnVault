import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/transactions_dao.dart';

/// Repository providing access to transaction history data.
class HistoryRepository {
  HistoryRepository({required TransactionsDao transactionsDao})
      : _transactionsDao = transactionsDao;

  final TransactionsDao _transactionsDao;

  /// Returns all transactions involving [address] (sent or received),
  /// ordered by timestamp descending.
  Future<List<Transaction>> getTransactionsForAddress(String address) =>
      _transactionsDao.getTransactionsForAddress(address);

  /// Persists a transaction, updating it if a row with the same [hash]
  /// already exists.
  Future<void> saveTransaction({
    required String hash,
    required String fromAddress,
    required String value,
    required int chainId,
    required String status,
    required DateTime timestamp,
    String? toAddress,
  }) =>
      _transactionsDao.upsertTransaction(
        TransactionsCompanion.insert(
          hash: hash,
          fromAddress: fromAddress,
          toAddress: Value(toAddress),
          value: value,
          chainId: chainId,
          status: status,
          timestamp: timestamp,
        ),
      );

  /// Returns the number of transactions involving [address].
  Future<int> countForAddress(String address) =>
      _transactionsDao.countForAddress(address);
}
