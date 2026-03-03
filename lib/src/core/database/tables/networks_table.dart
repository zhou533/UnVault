import 'package:drift/drift.dart';

class Networks extends Table {
  IntColumn get chainId => integer()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  IntColumn get decimals =>
      integer().withDefault(const Constant(18))();
  TextColumn get rpcUrl => text()();
  TextColumn get explorerUrl => text()();
  TextColumn get gasType =>
      text().withDefault(const Constant('eip1559'))();
  BoolColumn get isTestnet =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {chainId};
}
