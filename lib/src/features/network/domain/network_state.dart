import 'package:unvault/src/core/constants/chain_config.dart';

enum ConnectionStatus { connected, degraded, disconnected }

class NetworkState {
  const NetworkState({
    required this.activeChain,
    required this.connectionStatus,
    required this.activeRpcUrl,
  });

  final ChainConfig activeChain;
  final ConnectionStatus connectionStatus;
  final String activeRpcUrl;

  NetworkState copyWith({
    ChainConfig? activeChain,
    ConnectionStatus? connectionStatus,
    String? activeRpcUrl,
  }) {
    return NetworkState(
      activeChain: activeChain ?? this.activeChain,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      activeRpcUrl: activeRpcUrl ?? this.activeRpcUrl,
    );
  }
}
