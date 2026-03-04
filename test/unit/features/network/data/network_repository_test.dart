import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/networks_dao.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';

void main() {
  late AppDatabase database;
  late NetworksDao dao;
  late NetworkRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = NetworksDao(database);
    repository = NetworkRepository(dao);
  });

  tearDown(() async {
    await database.close();
  });

  group('NetworkRepository', () {
    group('seedBuiltInChains', () {
      test('populates all 8 built-in chains', () async {
        await repository.seedBuiltInChains();

        final networks = await repository.getAllNetworks();
        expect(networks, hasLength(BuiltInChains.all.length));
        expect(networks, hasLength(8));
      });

      test('seeded chains have correct data', () async {
        await repository.seedBuiltInChains();

        final eth = await dao.getByChainId(1);
        expect(eth, isNotNull);
        expect(eth!.name, equals('Ethereum'));
        expect(eth.symbol, equals('ETH'));
        expect(eth.decimals, equals(18));
        expect(eth.rpcUrl, equals('https://eth.llamarpc.com'));
        expect(eth.explorerUrl, equals('https://etherscan.io'));
        expect(eth.gasType, equals('eip1559'));
        expect(eth.isTestnet, isFalse);
        expect(eth.isCustom, isFalse);
      });

      test('seeded testnet chain is marked as testnet', () async {
        await repository.seedBuiltInChains();

        final sepolia = await dao.getByChainId(11155111);
        expect(sepolia, isNotNull);
        expect(sepolia!.name, equals('Sepolia'));
        expect(sepolia.isTestnet, isTrue);
        expect(sepolia.isCustom, isFalse);
      });

      test('seeded legacy gas chain has correct gas type', () async {
        await repository.seedBuiltInChains();

        final bsc = await dao.getByChainId(56);
        expect(bsc, isNotNull);
        expect(bsc!.name, equals('BNB Smart Chain'));
        expect(bsc.gasType, equals('legacy'));
      });

      test('is idempotent (upsert does not duplicate)', () async {
        await repository.seedBuiltInChains();
        await repository.seedBuiltInChains();

        final networks = await repository.getAllNetworks();
        expect(networks, hasLength(8));
      });
    });

    group('addCustomNetwork', () {
      test('inserts a custom network', () async {
        await repository.addCustomNetwork(
          const NetworksCompanion(
            chainId: Value(999),
            name: Value('Custom Chain'),
            symbol: Value('CUST'),
            decimals: Value(18),
            rpcUrl: Value('https://custom-rpc.example.com'),
            explorerUrl: Value('https://custom-explorer.example.com'),
            gasType: Value('eip1559'),
            isTestnet: Value(false),
            isCustom: Value(true),
          ),
        );

        final network = await dao.getByChainId(999);
        expect(network, isNotNull);
        expect(network!.name, equals('Custom Chain'));
        expect(network.symbol, equals('CUST'));
        expect(network.isCustom, isTrue);
      });

      test('custom network appears in getAllNetworks', () async {
        await repository.seedBuiltInChains();
        await repository.addCustomNetwork(
          const NetworksCompanion(
            chainId: Value(999),
            name: Value('Custom Chain'),
            symbol: Value('CUST'),
            decimals: Value(18),
            rpcUrl: Value('https://custom-rpc.example.com'),
            explorerUrl: Value('https://custom-explorer.example.com'),
            isCustom: Value(true),
          ),
        );

        final networks = await repository.getAllNetworks();
        expect(networks, hasLength(9));
      });
    });

    group('removeCustomNetwork', () {
      test('deletes a custom network', () async {
        await repository.addCustomNetwork(
          const NetworksCompanion(
            chainId: Value(999),
            name: Value('Custom Chain'),
            symbol: Value('CUST'),
            decimals: Value(18),
            rpcUrl: Value('https://custom-rpc.example.com'),
            explorerUrl: Value('https://custom-explorer.example.com'),
            isCustom: Value(true),
          ),
        );

        await repository.removeCustomNetwork(999);

        final network = await dao.getByChainId(999);
        expect(network, isNull);
      });

      test('does not affect other networks when removing one', () async {
        await repository.seedBuiltInChains();
        await repository.addCustomNetwork(
          const NetworksCompanion(
            chainId: Value(999),
            name: Value('Custom Chain'),
            symbol: Value('CUST'),
            decimals: Value(18),
            rpcUrl: Value('https://custom-rpc.example.com'),
            explorerUrl: Value('https://custom-explorer.example.com'),
            isCustom: Value(true),
          ),
        );

        await repository.removeCustomNetwork(999);

        final networks = await repository.getAllNetworks();
        expect(networks, hasLength(8));
      });
    });

    group('getAllNetworks', () {
      test('returns empty list when no networks exist', () async {
        final networks = await repository.getAllNetworks();
        expect(networks, isEmpty);
      });

      test('returns 8 entries after seeding', () async {
        await repository.seedBuiltInChains();

        final networks = await repository.getAllNetworks();
        expect(networks, hasLength(8));
      });
    });
  });
}
