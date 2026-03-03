import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get hash => text()();
  TextColumn get fromAddress => text()();
  TextColumn get toAddress => text().nullable()();
  TextColumn get value => text()();
  IntColumn get chainId => integer()();
  TextColumn get status => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {hash};
}
