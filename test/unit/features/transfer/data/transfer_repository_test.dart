import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/features/transfer/data/transfer_repository.dart';
import 'package:unvault/src/features/transfer/domain/transfer_request.dart';
import 'package:unvault/src/features/transfer/domain/transfer_result.dart';

void main() {
  group('TransferRepository', () {
    late RpcClient rpcClient;
    late TransferRepository repo;

    test('broadcastTransaction sends raw tx and returns tx hash', () async {
      rpcClient = RpcClient(
        url: 'http://localhost:8545',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final method = body['method'] as String;
          if (method == 'eth_sendRawTransaction') {
            return http.Response(
              jsonEncode({
                'jsonrpc': '2.0',
                'id': body['id'],
                'result':
                    '0xabc123def456789012345678901234567890123456789012345678901234abcd',
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
      );
      repo = TransferRepository(rpcClient: rpcClient);

      final result = await repo.broadcastTransaction('0xsignedrawtx');

      expect(result.txHash,
          '0xabc123def456789012345678901234567890123456789012345678901234abcd');
      expect(result.isSuccess, true);
    });

    test('broadcastTransaction returns failure on RPC error', () async {
      rpcClient = RpcClient(
        url: 'http://localhost:8545',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'error': {
                'code': -32000,
                'message': 'insufficient funds for gas',
              },
            }),
            200,
          );
        }),
      );
      repo = TransferRepository(rpcClient: rpcClient);

      final result = await repo.broadcastTransaction('0xsignedrawtx');

      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('insufficient funds'));
    });

    test('getNonce returns transaction count for address', () async {
      rpcClient = RpcClient(
        url: 'http://localhost:8545',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': body['id'],
              'result': '0x5',
            }),
            200,
          );
        }),
      );
      repo = TransferRepository(rpcClient: rpcClient);

      final nonce = await repo.getNonce('0x1234567890abcdef1234567890abcdef12345678');

      expect(nonce, 5);
    });
  });

  group('TransferRequest', () {
    test('creates with required fields', () {
      final request = TransferRequest(
        fromAddress: '0xaaa',
        toAddress: '0xbbb',
        amountWei: BigInt.from(1000000),
        gasLimit: BigInt.from(21000),
        chainId: 1,
      );

      expect(request.fromAddress, '0xaaa');
      expect(request.toAddress, '0xbbb');
      expect(request.amountWei, BigInt.from(1000000));
      expect(request.gasLimit, BigInt.from(21000));
      expect(request.chainId, 1);
    });

    test('supports EIP-1559 gas params', () {
      final request = TransferRequest(
        fromAddress: '0xaaa',
        toAddress: '0xbbb',
        amountWei: BigInt.from(1000000),
        gasLimit: BigInt.from(21000),
        chainId: 1,
        maxFeePerGas: BigInt.from(30000000000),
        maxPriorityFeePerGas: BigInt.from(2000000000),
      );

      expect(request.maxFeePerGas, BigInt.from(30000000000));
      expect(request.maxPriorityFeePerGas, BigInt.from(2000000000));
    });
  });

  group('TransferResult', () {
    test('success result has tx hash and no error', () {
      final result = TransferResult.success(
        txHash: '0xabc123',
      );

      expect(result.isSuccess, true);
      expect(result.txHash, '0xabc123');
      expect(result.errorMessage, isNull);
    });

    test('failure result has error message and no tx hash', () {
      final result = TransferResult.failure(
        errorMessage: 'insufficient funds',
      );

      expect(result.isSuccess, false);
      expect(result.txHash, isNull);
      expect(result.errorMessage, 'insufficient funds');
    });
  });
}
