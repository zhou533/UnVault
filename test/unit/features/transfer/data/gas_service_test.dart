import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/features/transfer/data/gas_service.dart';

void main() {
  group('GasService - EIP-1559 chain', () {
    test('estimates gas with three tiers from fee history', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'] as String;
        callCount++;

        if (method == 'eth_estimateGas') {
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': '0x5208'}),
            200,
          );
        }
        if (method == 'eth_feeHistory') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'baseFeePerGas': [
                  '0x6fc23ac00', // 30 gwei
                  '0x6fc23ac00',
                  '0x6fc23ac00',
                  '0x6fc23ac00',
                  '0x6fc23ac00',
                ],
                'reward': [
                  ['0x3b9aca00', '0x59682f00', '0x77359400'], // 1, 1.5, 2 gwei
                  ['0x3b9aca00', '0x59682f00', '0x77359400'],
                  ['0x3b9aca00', '0x59682f00', '0x77359400'],
                  ['0x3b9aca00', '0x59682f00', '0x77359400'],
                ],
              },
            }),
            200,
          );
        }
        return http.Response('', 500);
      });

      final rpcClient = RpcClient(url: 'https://test.rpc', httpClient: mockClient);
      final gasService = GasService(rpcClient: rpcClient);

      final estimate = await gasService.estimate(
        chain: BuiltInChains.ethereumMainnet,
        from: '0x1234567890123456789012345678901234567890',
        to: '0x0987654321098765432109876543210987654321',
        value: BigInt.from(1000000000000000000),
      );

      expect(estimate.gasLimit, BigInt.from(21000));
      expect(estimate.slow.label, 'Slow');
      expect(estimate.standard.label, 'Standard');
      expect(estimate.fast.label, 'Fast');
      // Priority fees are median of reward arrays
      expect(estimate.slow.maxPriorityFeePerGas, BigInt.from(1000000000));
      expect(estimate.standard.maxPriorityFeePerGas, BigInt.from(1500000000));
      expect(estimate.fast.maxPriorityFeePerGas, BigInt.from(2000000000));
      // totalCostWei = gasLimit * maxFeePerGas
      expect(estimate.slow.totalCostWei, estimate.gasLimit * estimate.slow.maxFeePerGas);
    });
  });

  group('GasService - Legacy chain', () {
    test('estimates gas with three tiers from gas price', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'] as String;

        if (method == 'eth_estimateGas') {
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': '0x5208'}),
            200,
          );
        }
        if (method == 'eth_gasPrice') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': '0x12a05f200', // 5 gwei
            }),
            200,
          );
        }
        return http.Response('', 500);
      });

      final rpcClient = RpcClient(url: 'https://test.rpc', httpClient: mockClient);
      final gasService = GasService(rpcClient: rpcClient);

      final estimate = await gasService.estimate(
        chain: BuiltInChains.bsc,
        from: '0x1234567890123456789012345678901234567890',
        to: '0x0987654321098765432109876543210987654321',
        value: BigInt.from(1000000000000000000),
      );

      expect(estimate.gasLimit, BigInt.from(21000));
      // Legacy: gasPrice * multipliers 0.9x / 1.0x / 1.2x
      final baseGasPrice = BigInt.from(5000000000);
      expect(estimate.slow.gasPrice, baseGasPrice * BigInt.from(90) ~/ BigInt.from(100));
      expect(estimate.standard.gasPrice, baseGasPrice);
      expect(estimate.fast.gasPrice, baseGasPrice * BigInt.from(120) ~/ BigInt.from(100));
    });
  });

  group('GasService - gas limit buffer', () {
    test('adds 20% buffer to estimated gas for non-simple transfers', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final method = body['method'] as String;

        if (method == 'eth_estimateGas') {
          return http.Response(
            jsonEncode({'jsonrpc': '2.0', 'id': body['id'], 'result': '0xea60'}), // 60000
            200,
          );
        }
        if (method == 'eth_feeHistory') {
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': {
                'baseFeePerGas': ['0x6fc23ac00', '0x6fc23ac00'],
                'reward': [['0x3b9aca00', '0x59682f00', '0x77359400']],
              },
            }),
            200,
          );
        }
        return http.Response('', 500);
      });

      final rpcClient = RpcClient(url: 'https://test.rpc', httpClient: mockClient);
      final gasService = GasService(rpcClient: rpcClient);

      final estimate = await gasService.estimate(
        chain: BuiltInChains.ethereumMainnet,
        from: '0x1234567890123456789012345678901234567890',
        to: '0x0987654321098765432109876543210987654321',
        value: BigInt.zero,
      );

      // 60000 * 1.2 = 72000
      expect(estimate.gasLimit, BigInt.from(72000));
    });
  });
}
