import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/transactions_dao.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

class HistoryRepository {
  const HistoryRepository({required TransactionsDao dao}) : _dao = dao;

  final TransactionsDao _dao;

  Future<List<TransactionRecord>> getTransactions({
    required int chainId,
    required String address,
    required int limit,
    required int offset,
  }) async {
    final rows = await _dao.getTransactions(
      chainId: chainId,
      address: address,
      limit: limit,
      offset: offset,
    );
    return rows.map(_mapRow).toList();
  }

  Future<void> insertTransaction(TransactionRecord record) async {
    await _dao.upsertTransaction(TransactionsCompanion.insert(
      hash: record.txHash,
      fromAddress: record.from,
      toAddress: Value(record.to),
      value: record.value.toString(),
      chainId: record.chainId,
      status: record.status.name,
      timestamp: record.timestamp,
    ));
  }

  Future<void> updateStatus(
      String txHash, TransactionStatus status) async {
    await _dao.updateStatus(txHash, status.name);
  }

  TransactionRecord _mapRow(Transaction row) {
    return TransactionRecord(
      txHash: row.hash,
      from: row.fromAddress,
      to: row.toAddress ?? '',
      value: BigInt.parse(row.value),
      chainId: row.chainId,
      status: TransactionStatus.values.byName(row.status),
      timestamp: row.timestamp,
      nonce: 0, // nonce not stored in current schema
    );
  }
}
