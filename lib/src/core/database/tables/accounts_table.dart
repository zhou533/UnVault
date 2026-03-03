import 'package:drift/drift.dart';

import 'package:unvault/src/core/database/tables/wallets_table.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId =>
      integer().references(Wallets, #id)();
  IntColumn get derivationIndex => integer()();
  TextColumn get address => text().withLength(min: 42, max: 42)();
  TextColumn get name =>
      text().withLength(min: 1, max: 50).nullable()();
}
