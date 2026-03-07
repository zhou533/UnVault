import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/accounts_table.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<List<Account>> getAccountsForWallet(int walletId) {
    return (select(accounts)..where((a) => a.walletId.equals(walletId))).get();
  }

  Future<int> insertAccount(AccountsCompanion account) =>
      into(accounts).insert(account);

  Future<int> countAccountsForWallet(int walletId) {
    return customSelect(
      'SELECT COUNT(*) AS count FROM accounts WHERE wallet_id = ?',
      variables: [Variable.withInt(walletId)],
      readsFrom: {accounts},
    ).map((row) => row.read<int>('count')).getSingle();
  }

  Future<void> deleteAccountsForWallet(int walletId) async {
    await (delete(accounts)..where((a) => a.walletId.equals(walletId))).go();
  }
}
