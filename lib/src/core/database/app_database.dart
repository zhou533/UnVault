import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:unvault/src/core/database/tables/accounts_table.dart';
import 'package:unvault/src/core/database/tables/networks_table.dart';
import 'package:unvault/src/core/database/tables/transactions_table.dart';
import 'package:unvault/src/core/database/tables/wallets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Accounts, Transactions, Networks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'unvault');
  }
}
