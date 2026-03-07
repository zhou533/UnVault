import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/domain/network_state.dart';

void main() {
  group('NetworkState', () {
    test('creates with required fields', () {
      final state = NetworkState(
        activeChain: BuiltInChains.ethereumMainnet,
        connectionStatus: ConnectionStatus.connected,
        activeRpcUrl: 'https://eth.llamarpc.com',
      );

      expect(state.activeChain.chainId, 1);
      expect(state.connectionStatus, ConnectionStatus.connected);
      expect(state.activeRpcUrl, 'https://eth.llamarpc.com');
    });

    test('copyWith changes active chain', () {
      final state = NetworkState(
        activeChain: BuiltInChains.ethereumMainnet,
        connectionStatus: ConnectionStatus.connected,
        activeRpcUrl: 'https://eth.llamarpc.com',
      );

      final updated = state.copyWith(
        activeChain: BuiltInChains.polygon,
        activeRpcUrl: 'https://polygon-rpc.com',
      );

      expect(updated.activeChain.chainId, 137);
      expect(updated.activeRpcUrl, 'https://polygon-rpc.com');
      expect(updated.connectionStatus, ConnectionStatus.connected);
    });

    test('ConnectionStatus has expected values', () {
      expect(ConnectionStatus.values, hasLength(3));
      expect(
        ConnectionStatus.values,
        containsAll([
          ConnectionStatus.connected,
          ConnectionStatus.degraded,
          ConnectionStatus.disconnected,
        ]),
      );
    });
  });
}
