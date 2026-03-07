import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/rpc_client.dart';

void main() {
  group('RpcClient', () {
    late RpcClient client;

    http.Client mockHttpClient(Object result) {
      return MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': result,
          }),
          200,
        );
      });
    }

    http.Client mockErrorClient(String message) {
      return MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'error': {'code': -32000, 'message': message},
          }),
          200,
        );
      });
    }

    test('call sends correct JSON-RPC request', () async {
      String? capturedBody;
      final httpClient = MockClient((request) async {
        capturedBody = request.body;
        expect(request.url.toString(), 'https://rpc.example.com');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': 1, 'result': '0x1'}),
          200,
        );
      });

      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: httpClient,
      );

      await client.call('eth_blockNumber');
      final parsed = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(parsed['method'], 'eth_blockNumber');
      expect(parsed['jsonrpc'], '2.0');
    });

    test('getBalance returns BigInt from hex', () async {
      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: mockHttpClient('0xde0b6b3a7640000'), // 1 ETH in wei
      );

      final balance =
          await client.getBalance('0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18');
      expect(balance, BigInt.parse('1000000000000000000'));
    });

    test('getBlockNumber returns int from hex', () async {
      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: mockHttpClient('0x10d4f1'), // 1103089
      );

      final blockNumber = await client.getBlockNumber();
      expect(blockNumber, 0x10d4f1);
    });

    test('getTransactionCount returns int from hex', () async {
      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: mockHttpClient('0x5'),
      );

      final count = await client
          .getTransactionCount('0x742d35Cc6634C0532925a3b844Bc9e7595f2bD18');
      expect(count, 5);
    });

    test('getGasPrice returns BigInt from hex', () async {
      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: mockHttpClient('0x3b9aca00'), // 1 gwei
      );

      final gasPrice = await client.getGasPrice();
      expect(gasPrice, BigInt.from(1000000000));
    });

    test('throws RpcException on JSON-RPC error', () async {
      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: mockErrorClient('execution reverted'),
      );

      expect(
        () => client.call('eth_call'),
        throwsA(isA<RpcException>()),
      );
    });

    test('throws RpcException on HTTP error', () async {
      final httpClient = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      client = RpcClient(
        url: 'https://rpc.example.com',
        httpClient: httpClient,
      );

      expect(
        () => client.call('eth_blockNumber'),
        throwsA(isA<RpcException>()),
      );
    });
  });
}
