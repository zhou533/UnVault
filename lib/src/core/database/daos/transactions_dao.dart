import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/transactions_table.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future<List<Transaction>> getTransactionsForAddress(String address) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.fromAddress.equals(address) |
                  t.toAddress.equals(address),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
          .get();

  Future<void> upsertTransaction(TransactionsCompanion tx) =>
      into(transactions).insertOnConflictUpdate(tx);

  Future<int> countForAddress(String address) async {
    final count = await (selectOnly(transactions)
          ..addColumns([transactions.hash.count()])
          ..where(
            transactions.fromAddress.equals(address) |
                transactions.toAddress.equals(address),
          ))
        .map((row) => row.read(transactions.hash.count())!)
        .getSingle();
    return count;
  }
}
