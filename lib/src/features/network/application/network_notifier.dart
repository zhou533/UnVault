import 'package:flutter/foundation.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';
import 'package:unvault/src/features/network/domain/network_state.dart';

/// Manages active network/chain state.
/// Uses ChangeNotifier for compatibility with both vanilla and Riverpod.
class NetworkNotifier extends ChangeNotifier {
  NetworkNotifier(this._repo) {
    final defaultChain = _repo.getDefaultChain();
    _state = NetworkState(
      activeChain: defaultChain,
      connectionStatus: ConnectionStatus.connected,
      activeRpcUrl: defaultChain.rpcUrls.first,
    );
  }

  final NetworkRepository _repo;
  late NetworkState _state;

  NetworkState get state => _state;

  List<ChainConfig> get availableChains => _repo.getAllChains();

  void switchChain(int chainId) {
    final chain = _repo.getChainById(chainId);
    if (chain == null) return;

    _state = _state.copyWith(
      activeChain: chain,
      activeRpcUrl: chain.rpcUrls.first,
    );
    notifyListeners();
  }

  void updateConnectionStatus(ConnectionStatus status) {
    _state = _state.copyWith(connectionStatus: status);
    notifyListeners();
  }
}
