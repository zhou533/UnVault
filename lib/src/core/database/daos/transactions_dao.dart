import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getTransactions({
    required int chainId,
    required String address,
    required int limit,
    required int offset,
  }) {
    return (select(transactions)
          ..where((t) =>
              t.chainId.equals(chainId) &
              (t.fromAddress.equals(address) | t.toAddress.equals(address)))
          ..orderBy([
            (t) => OrderingTerm.desc(t.timestamp),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<void> upsertTransaction(TransactionsCompanion tx) async {
    await into(transactions).insertOnConflictUpdate(tx);
  }

  Future<void> updateStatus(String hash, String status) async {
    await (update(transactions)..where((t) => t.hash.equals(hash)))
        .write(TransactionsCompanion(status: Value(status)));
  }

  Future<List<Transaction>> getPendingTransactions() {
    return (select(transactions)
          ..where((t) => t.status.equals('pending')))
        .get();
  }

  Future<List<Transaction>> searchByHash(String hashPrefix) {
    return (select(transactions)
          ..where((t) => t.hash.like('$hashPrefix%'))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(20))
        .get();
  }

  Future<List<Transaction>> searchByAddress(String address, int chainId) {
    return (select(transactions)
          ..where((t) =>
              t.chainId.equals(chainId) &
              (t.fromAddress.like('%$address%') |
                  t.toAddress.like('%$address%')))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(20))
        .get();
  }
}
