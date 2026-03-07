import 'dart:convert';

import 'package:http/http.dart' as http;

/// Exception thrown when an RPC call fails.
class RpcException implements Exception {
  const RpcException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => 'RpcException($code): $message';
}

/// JSON-RPC 2.0 client for Ethereum nodes.
class RpcClient {
  RpcClient({
    required this.url,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _httpClient = httpClient ?? http.Client();

  final String url;
  final Duration timeout;
  final http.Client _httpClient;

  int _requestId = 0;

  /// Generic JSON-RPC call.
  Future<dynamic> call(String method, [List<dynamic>? params]) async {
    final id = ++_requestId;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'method': method,
      'params': params ?? [],
      'id': id,
    });

    final http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on Exception catch (e) {
      throw RpcException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw RpcException(
        'HTTP ${response.statusCode}: ${response.body}',
        code: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json.containsKey('error')) {
      final error = json['error'] as Map<String, dynamic>;
      throw RpcException(
        error['message'] as String? ?? 'Unknown RPC error',
        code: error['code'] as int?,
      );
    }

    return json['result'];
  }

  /// Get native balance for an address.
  Future<BigInt> getBalance(String address) async {
    final result = await call('eth_getBalance', [address, 'latest']);
    return BigInt.parse(result as String);
  }

  /// Get latest block number.
  Future<int> getBlockNumber() async {
    final result = await call('eth_blockNumber');
    return int.parse(result as String);
  }

  /// Get chain ID.
  Future<BigInt> getChainId() async {
    final result = await call('eth_chainId');
    return BigInt.parse(result as String);
  }

  /// Send a signed raw transaction.
  Future<String> sendRawTransaction(String rawTx) async {
    final result = await call('eth_sendRawTransaction', [rawTx]);
    return result as String;
  }

  /// Get gas price.
  Future<BigInt> getGasPrice() async {
    final result = await call('eth_gasPrice');
    return BigInt.parse(result as String);
  }

  /// Get transaction count (nonce) for an address.
  Future<int> getTransactionCount(String address) async {
    final result =
        await call('eth_getTransactionCount', [address, 'latest']);
    return int.parse(result as String);
  }

  /// Estimate gas for a transaction.
  Future<BigInt> estimateGas(Map<String, dynamic> txParams) async {
    final result = await call('eth_estimateGas', [txParams]);
    return BigInt.parse(result as String);
  }

  /// Get fee history for EIP-1559 gas estimation.
  Future<Map<String, dynamic>> getFeeHistory(
    int blockCount,
    String newest,
    List<int> percentiles,
  ) async {
    final result = await call('eth_feeHistory', [
      '0x${blockCount.toRadixString(16)}',
      newest,
      percentiles,
    ]);
    return result as Map<String, dynamic>;
  }

  /// Dispose the underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }
}
