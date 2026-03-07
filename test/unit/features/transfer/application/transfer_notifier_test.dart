import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/features/transfer/application/transfer_notifier.dart';
import 'package:unvault/src/features/transfer/data/transfer_repository.dart';
import 'package:unvault/src/features/transfer/domain/transfer_request.dart';

void main() {
  group('TransferNotifier', () {
    late TransferNotifier notifier;

    test('initial state is idle', () {
      final repo = TransferRepository(
        rpcClient: RpcClient(
          url: 'http://localhost:8545',
          httpClient: MockClient((_) async => http.Response('', 200)),
        ),
      );
      notifier = TransferNotifier(repository: repo);

      expect(notifier.state.status, TransferStatus.idle);
      expect(notifier.state.result, isNull);
    });

    test('submitTransaction transitions to broadcasting then success', () async {
      final repo = TransferRepository(
        rpcClient: RpcClient(
          url: 'http://localhost:8545',
          httpClient: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final method = body['method'] as String;
            if (method == 'eth_sendRawTransaction') {
              return http.Response(
                jsonEncode({
                  'jsonrpc': '2.0',
                  'id': body['id'],
                  'result': '0xtxhash123',
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'error': {'code': -32601, 'message': 'Method not found'},
              }),
              200,
            );
          }),
        ),
      );
      notifier = TransferNotifier(repository: repo);

      final states = <TransferStatus>[];
      notifier.addListener(() {
        states.add(notifier.state.status);
      });

      await notifier.submitTransaction(signedRawTx: '0xsigned');

      expect(states, [TransferStatus.broadcasting, TransferStatus.success]);
      expect(notifier.state.result?.txHash, '0xtxhash123');
      expect(notifier.state.result?.isSuccess, true);
    });

    test('submitTransaction transitions to broadcasting then failed on error',
        () async {
      final repo = TransferRepository(
        rpcClient: RpcClient(
          url: 'http://localhost:8545',
          httpClient: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'error': {
                  'code': -32000,
                  'message': 'nonce too low',
                },
              }),
              200,
            );
          }),
        ),
      );
      notifier = TransferNotifier(repository: repo);

      final states = <TransferStatus>[];
      notifier.addListener(() {
        states.add(notifier.state.status);
      });

      await notifier.submitTransaction(signedRawTx: '0xsigned');

      expect(states, [TransferStatus.broadcasting, TransferStatus.failed]);
      expect(notifier.state.result?.isSuccess, false);
      expect(notifier.state.result?.errorMessage, contains('nonce too low'));
    });

    test('reset returns to idle state', () async {
      final repo = TransferRepository(
        rpcClient: RpcClient(
          url: 'http://localhost:8545',
          httpClient: MockClient((request) async {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'result': '0xtxhash',
              }),
              200,
            );
          }),
        ),
      );
      notifier = TransferNotifier(repository: repo);
      await notifier.submitTransaction(signedRawTx: '0xsigned');
      expect(notifier.state.status, TransferStatus.success);

      notifier.reset();

      expect(notifier.state.status, TransferStatus.idle);
      expect(notifier.state.result, isNull);
    });
  });
}
