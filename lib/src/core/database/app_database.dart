import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:unvault/src/core/database/daos/accounts_dao.dart';
import 'package:unvault/src/core/database/daos/networks_dao.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/database/tables/accounts_table.dart';
import 'package:unvault/src/core/database/tables/networks_table.dart';
import 'package:unvault/src/core/database/tables/transactions_table.dart';
import 'package:unvault/src/core/database/tables/wallets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Wallets, Accounts, Transactions, Networks],
  daos: [WalletsDao, AccountsDao, NetworksDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Creates an [AppDatabase] with a custom [QueryExecutor].
  ///
  /// Used for testing with an in-memory database.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'unvault');
  }

  @override
  WalletsDao get walletsDao => WalletsDao(this);

  @override
  AccountsDao get accountsDao => AccountsDao(this);

  @override
  NetworksDao get networksDao => NetworksDao(this);

  Future<int> walletCount() {
    return customSelect(
      'SELECT COUNT(*) AS count FROM wallets',
      readsFrom: {wallets},
    ).map((row) => row.read<int>('count')).getSingle();
  }
}
