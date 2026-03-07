import 'package:unvault/src/core/constants/chain_config.dart';

/// Repository for chain/network data.
/// Currently backed by in-memory built-in chains.
/// Will be extended with drift persistence for custom RPCs in Phase 5.
class NetworkRepository {
  List<ChainConfig> getAllChains() => BuiltInChains.all;

  ChainConfig? getChainById(int chainId) {
    for (final chain in BuiltInChains.all) {
      if (chain.chainId == chainId) return chain;
    }
    return null;
  }

  ChainConfig getDefaultChain() => BuiltInChains.ethereumMainnet;
}
