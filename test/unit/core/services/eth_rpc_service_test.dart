import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/eth_rpc_service.dart';

const _rpcUrl = 'https://rpc.test';

/// Helper to build a successful JSON-RPC response body.
String _successBody(dynamic result, {int id = 1}) => jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    });

/// Helper to build an error JSON-RPC response body.
String _errorBody({
  required int code,
  required String message,
  int id = 1,
}) =>
    jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    });

void main() {
  late EthRpcService service;

  group('call', () {
    test('sends correct JSON-RPC payload', () async {
      final mockClient = MockClient((req) async {
        expect(req.url, Uri.parse(_rpcUrl));
        expect(req.headers['Content-Type'], 'application/json');

        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['jsonrpc'], '2.0');
        expect(body['method'], 'eth_blockNumber');
        expect(body['params'], <dynamic>[]);
        expect(body['id'], isA<int>());

        return http.Response(_successBody('0x10'), 200);
      });
      service = EthRpcService(client: mockClient);

      final result = await service.call(_rpcUrl, 'eth_blockNumber');
      expect(result, '0x10');
    });

    test('passes params through', () async {
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['params'], ['0xabc', 'latest']);
        return http.Response(_successBody('0x1'), 200);
      });
      service = EthRpcService(client: mockClient);

      await service.call(
        _rpcUrl,
        'eth_getBalance',
        ['0xabc', 'latest'],
      );
    });

    test('increments request id', () async {
      final ids = <int>[];
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        ids.add(body['id'] as int);
        return http.Response(_successBody('0x1'), 200);
      });
      service = EthRpcService(client: mockClient);

      await service.call(_rpcUrl, 'eth_blockNumber');
      await service.call(_rpcUrl, 'eth_blockNumber');
      await service.call(_rpcUrl, 'eth_blockNumber');

      expect(ids, [1, 2, 3]);
    });
  });

  group('getBalance', () {
    test('parses hex balance to BigInt', () async {
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_getBalance');
        expect(body['params'], ['0xabc', 'latest']);
        return http.Response(
          _successBody('0xDE0B6B3A7640000'),
          200,
        );
      });
      service = EthRpcService(client: mockClient);

      final balance =
          await service.getBalance(_rpcUrl, '0xabc');
      // 0xDE0B6B3A7640000 = 1e18 = 1 ETH in wei
      expect(balance, BigInt.parse('1000000000000000000'));
    });

    test('handles zero balance', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _successBody('0x0'),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      final balance =
          await service.getBalance(_rpcUrl, '0xabc');
      expect(balance, BigInt.zero);
    });
  });

  group('getTransactionCount', () {
    test('parses hex nonce to int', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _successBody('0x5'),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      final nonce = await service.getTransactionCount(
        _rpcUrl,
        '0xabc',
      );
      expect(nonce, 5);
    });

    test('handles zero nonce', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _successBody('0x0'),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      final nonce = await service.getTransactionCount(
        _rpcUrl,
        '0xabc',
      );
      expect(nonce, 0);
    });
  });

  group('estimateGas', () {
    test('parses hex gas estimate to int', () async {
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_estimateGas');
        return http.Response(
          _successBody('0x5208'),
          200,
        );
      });
      service = EthRpcService(client: mockClient);

      final gas = await service.estimateGas(
        _rpcUrl,
        {'from': '0xabc', 'to': '0xdef'},
      );
      expect(gas, 21000); // 0x5208 = 21000
    });
  });

  group('getEip1559Fees', () {
    test('returns baseFee and priorityFee', () async {
      var callCount = 0;
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        callCount++;
        if (body['method'] == 'eth_getBlockByNumber') {
          return http.Response(
            _successBody({
              'baseFeePerGas': '0x3B9ACA00', // 1 Gwei
              'number': '0x100',
            }),
            200,
          );
        }
        if (body['method'] == 'eth_maxPriorityFeePerGas') {
          return http.Response(
            _successBody('0x77359400'), // 2 Gwei
            200,
          );
        }
        fail('Unexpected method: ${body['method']}');
      });
      service = EthRpcService(client: mockClient);

      final fees = await service.getEip1559Fees(_rpcUrl);
      expect(
        fees.baseFee,
        BigInt.from(1000000000), // 1 Gwei
      );
      expect(
        fees.priorityFee,
        BigInt.from(2000000000), // 2 Gwei
      );
      expect(callCount, 2);
    });
  });

  group('sendRawTransaction', () {
    test('sends raw tx and returns hash', () async {
      const txHash =
          '0xabc123def456789012345678901234567890';
      final mockClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_sendRawTransaction');
        expect(body['params'], ['0xsignedtx']);
        return http.Response(
          _successBody(txHash),
          200,
        );
      });
      service = EthRpcService(client: mockClient);

      final hash = await service.sendRawTransaction(
        _rpcUrl,
        '0xsignedtx',
      );
      expect(hash, txHash);
    });
  });

  group('getTransactionReceipt', () {
    test('returns receipt map when confirmed', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _successBody({
            'status': '0x1',
            'blockNumber': '0x100',
            'transactionHash': '0xabc',
          }),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      final receipt = await service.getTransactionReceipt(
        _rpcUrl,
        '0xabc',
      );
      expect(receipt, isNotNull);
      expect(receipt!['status'], '0x1');
    });

    test('returns null when pending', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _successBody(null),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      final receipt = await service.getTransactionReceipt(
        _rpcUrl,
        '0xabc',
      );
      expect(receipt, isNull);
    });
  });

  group('error handling', () {
    test('throws RpcException on JSON-RPC error', () async {
      final mockClient = MockClient(
        (req) async => http.Response(
          _errorBody(code: -32000, message: 'nope'),
          200,
        ),
      );
      service = EthRpcService(client: mockClient);

      expect(
        () => service.getBalance(_rpcUrl, '0xabc'),
        throwsA(
          isA<RpcException>()
              .having((e) => e.code, 'code', -32000)
              .having(
                (e) => e.message,
                'message',
                'nope',
              ),
        ),
      );
    });

    test('throws RpcException on HTTP error', () async {
      final mockClient = MockClient(
        (req) async => http.Response('', 500),
      );
      service = EthRpcService(client: mockClient);

      expect(
        () => service.getBalance(_rpcUrl, '0xabc'),
        throwsA(
          isA<RpcException>()
              .having((e) => e.code, 'code', -1)
              .having(
                (e) => e.message,
                'message',
                'HTTP 500',
              ),
        ),
      );
    });

    test('RpcException toString formats correctly', () {
      const exception = RpcException(-32000, 'test error');
      expect(
        exception.toString(),
        'RpcException(-32000): test error',
      );
    });
  });
}
