import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';
import 'package:unvault/src/features/network/domain/network_state.dart';

void main() {
  group('NetworkNotifier', () {
    late NetworkNotifier notifier;
    late NetworkRepository repo;

    setUp(() {
      repo = NetworkRepository();
      notifier = NetworkNotifier(repo);
    });

    test('initial state is Ethereum mainnet, connected', () {
      expect(notifier.state.activeChain.chainId, 1);
      expect(notifier.state.connectionStatus, ConnectionStatus.connected);
      expect(notifier.state.activeRpcUrl, 'https://eth.llamarpc.com');
    });

    test('switchChain changes active chain', () {
      notifier.switchChain(137);
      expect(notifier.state.activeChain.chainId, 137);
      expect(notifier.state.activeChain.name, 'Polygon');
      expect(notifier.state.activeRpcUrl, 'https://polygon-rpc.com');
    });

    test('switchChain to unknown chain does nothing', () {
      notifier.switchChain(999999);
      expect(notifier.state.activeChain.chainId, 1); // Still Ethereum
    });

    test('updateConnectionStatus changes status', () {
      notifier.updateConnectionStatus(ConnectionStatus.degraded);
      expect(notifier.state.connectionStatus, ConnectionStatus.degraded);
    });

    test('availableChains returns all chains from repo', () {
      expect(notifier.availableChains.length, BuiltInChains.all.length);
    });
  });
}
