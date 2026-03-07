import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/core/services/rpc_failover_manager.dart';

void main() {
  group('RpcFailoverManager', () {
    http.Client successClient(Object result) {
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

    test('executes action on primary URL', () async {
      final manager = RpcFailoverManager(
        rpcUrls: ['https://primary.rpc', 'https://backup.rpc'],
        httpClientFactory: (_) => successClient('0x1'),
      );

      final result = await manager.execute((client) => client.getBlockNumber());
      expect(result, 1);
    });

    test('fails over to backup URL when primary fails', () async {
      int callCount = 0;
      final manager = RpcFailoverManager(
        rpcUrls: ['https://primary.rpc', 'https://backup.rpc'],
        maxRetries: 1,
        httpClientFactory: (url) {
          if (url == 'https://primary.rpc') {
            return MockClient((_) async => http.Response('error', 500));
          }
          return successClient('0x2');
        },
      );

      final result = await manager.execute((client) => client.getBlockNumber());
      expect(result, 2);
    });

    test('throws after all URLs exhausted', () async {
      final manager = RpcFailoverManager(
        rpcUrls: ['https://primary.rpc', 'https://backup.rpc'],
        maxRetries: 1,
        httpClientFactory: (_) =>
            MockClient((_) async => http.Response('error', 500)),
      );

      expect(
        () => manager.execute((client) => client.getBlockNumber()),
        throwsA(isA<RpcException>()),
      );
    });

    test('retries on same URL before failing over', () async {
      int primaryCalls = 0;
      final manager = RpcFailoverManager(
        rpcUrls: ['https://primary.rpc', 'https://backup.rpc'],
        maxRetries: 2,
        baseRetryDelay: Duration.zero,
        httpClientFactory: (url) {
          if (url == 'https://primary.rpc') {
            return MockClient((_) async {
              primaryCalls++;
              return http.Response('error', 500);
            });
          }
          return successClient('0x3');
        },
      );

      final result = await manager.execute((client) => client.getBlockNumber());
      expect(primaryCalls, 2); // Retried on primary
      expect(result, 3); // Then succeeded on backup
    });
  });
}
