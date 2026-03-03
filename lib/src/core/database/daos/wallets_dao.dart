import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/wallets_table.dart';

part 'wallets_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletsDao extends DatabaseAccessor<AppDatabase> with _$WalletsDaoMixin {
  WalletsDao(super.db);

  Future<List<Wallet>> getAllWallets() => select(wallets).get();

  Future<Wallet?> getWalletById(int id) {
    return (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertWallet(WalletsCompanion wallet) =>
      into(wallets).insert(wallet);

  Future<void> markBackedUp(int id) async {
    await (update(wallets)..where((w) => w.id.equals(id)))
        .write(const WalletsCompanion(isBackedUp: Value(true)));
  }

  Future<int> countWallets() {
    return customSelect(
      'SELECT COUNT(*) AS count FROM wallets',
      readsFrom: {wallets},
    ).map((row) => row.read<int>('count')).getSingle();
  }
}
