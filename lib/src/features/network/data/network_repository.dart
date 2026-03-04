import 'package:drift/drift.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/networks_dao.dart';

class NetworkRepository {
  NetworkRepository(this._dao);
  final NetworksDao _dao;

  /// Seeds built-in chains on first launch.
  Future<void> seedBuiltInChains() async {
    for (final chain in BuiltInChains.all) {
      await _dao.upsertNetwork(
        NetworksCompanion(
          chainId: Value(chain.chainId),
          name: Value(chain.name),
          symbol: Value(chain.symbol),
          decimals: Value(chain.decimals),
          rpcUrl: Value(chain.rpcUrls.first),
          explorerUrl: Value(chain.explorerUrl),
          gasType: Value(chain.gasType.name),
          isTestnet: Value(chain.isTestnet),
          isCustom: const Value(false),
        ),
      );
    }
  }

  Future<List<Network>> getAllNetworks() => _dao.getAllNetworks();

  Future<void> addCustomNetwork(NetworksCompanion network) =>
      _dao.upsertNetwork(network);

  Future<void> removeCustomNetwork(int chainId) =>
      _dao.deleteNetwork(chainId);
}
