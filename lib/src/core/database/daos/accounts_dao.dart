import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/accounts_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAccountsForWallet(int walletId) =>
      (select(accounts)..where((a) => a.walletId.equals(walletId))).get();

  Future<Account?> getAccount(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<int> countAccountsForWallet(int walletId) async {
    final result = await (selectOnly(accounts)
          ..addColumns([accounts.id.count()])
          ..where(accounts.walletId.equals(walletId)))
        .map((row) => row.read(accounts.id.count())!)
        .getSingle();
    return result;
  }
}
