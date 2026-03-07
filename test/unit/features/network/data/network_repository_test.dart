import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';

void main() {
  group('NetworkRepository', () {
    late NetworkRepository repo;

    setUp(() {
      repo = NetworkRepository();
    });

    test('getAllChains returns all built-in chains', () {
      final chains = repo.getAllChains();
      expect(chains.length, BuiltInChains.all.length);
    });

    test('getChainById returns correct chain', () {
      final chain = repo.getChainById(1);
      expect(chain, isNotNull);
      expect(chain!.name, 'Ethereum');
    });

    test('getChainById returns null for unknown chain', () {
      final chain = repo.getChainById(999999);
      expect(chain, isNull);
    });

    test('getDefaultChain returns Ethereum mainnet', () {
      final chain = repo.getDefaultChain();
      expect(chain.chainId, 1);
    });
  });
}
