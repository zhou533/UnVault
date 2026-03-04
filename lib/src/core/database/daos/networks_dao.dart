import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/tables/networks_table.dart';

part 'networks_dao.g.dart';

@DriftAccessor(tables: [Networks])
class NetworksDao extends DatabaseAccessor<AppDatabase>
    with _$NetworksDaoMixin {
  NetworksDao(super.db);

  Future<List<Network>> getAllNetworks() => select(networks).get();

  Future<Network?> getByChainId(int chainId) =>
      (select(networks)..where((n) => n.chainId.equals(chainId)))
          .getSingleOrNull();

  Future<void> upsertNetwork(NetworksCompanion network) =>
      into(networks).insertOnConflictUpdate(network);

  Future<void> deleteNetwork(int chainId) =>
      (delete(networks)..where((n) => n.chainId.equals(chainId))).go();

  Future<List<Network>> getCustomNetworks() =>
      (select(networks)..where((n) => n.isCustom.equals(true))).get();
}
