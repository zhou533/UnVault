import 'dart:convert';

import 'package:http/http.dart' as http;

/// Exception thrown when a JSON-RPC call fails at the protocol
/// level (HTTP error) or at the JSON-RPC level (error response).
class RpcException implements Exception {
  const RpcException(this.code, this.message);

  final int code;
  final String message;

  @override
  String toString() => 'RpcException($code): $message';
}

/// Thin wrapper around Ethereum JSON-RPC over HTTP.
///
/// All blockchain queries flow through this single service.
/// Accepts an optional [http.Client] for testability.
class EthRpcService {
  EthRpcService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  int _requestId = 0;

  /// Raw JSON-RPC call. Returns the `result` field or throws
  /// [RpcException].
  Future<dynamic> call(
    String rpcUrl,
    String method, [
    List<dynamic> params = const [],
  ]) async {
    final id = ++_requestId;
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });

    final response = await _client.post(
      Uri.parse(rpcUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw RpcException(
        -1,
        'HTTP ${response.statusCode}',
      );
    }

    final json =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (json.containsKey('error')) {
      final err = json['error'] as Map<String, dynamic>;
      throw RpcException(
        err['code'] as int,
        err['message'] as String,
      );
    }

    return json['result'];
  }

  /// Returns balance in wei as [BigInt].
  Future<BigInt> getBalance(
    String rpcUrl,
    String address,
  ) async {
    final hex = await call(
      rpcUrl,
      'eth_getBalance',
      [address, 'latest'],
    ) as String;
    return BigInt.parse(hex);
  }

  /// Returns current nonce for [address].
  Future<int> getTransactionCount(
    String rpcUrl,
    String address,
  ) async {
    final hex = await call(
      rpcUrl,
      'eth_getTransactionCount',
      [address, 'latest'],
    ) as String;
    return int.parse(hex);
  }

  /// Returns gas estimate as [int].
  Future<int> estimateGas(
    String rpcUrl,
    Map<String, dynamic> txObj,
  ) async {
    final hex = await call(
      rpcUrl,
      'eth_estimateGas',
      [txObj],
    ) as String;
    return int.parse(hex);
  }

  /// Returns EIP-1559 fee data: base fee and priority fee.
  Future<({BigInt baseFee, BigInt priorityFee})>
      getEip1559Fees(String rpcUrl) async {
    final block = await call(
      rpcUrl,
      'eth_getBlockByNumber',
      ['latest', false],
    ) as Map<String, dynamic>;
    final baseFee =
        BigInt.parse(block['baseFeePerGas'] as String);

    final priorityHex = await call(
      rpcUrl,
      'eth_maxPriorityFeePerGas',
    ) as String;
    final priorityFee = BigInt.parse(priorityHex);

    return (baseFee: baseFee, priorityFee: priorityFee);
  }

  /// Broadcasts a signed raw transaction. Returns the tx
  /// hash.
  Future<String> sendRawTransaction(
    String rpcUrl,
    String rawTxHex,
  ) async {
    return await call(
      rpcUrl,
      'eth_sendRawTransaction',
      [rawTxHex],
    ) as String;
  }

  /// Gets transaction receipt. Returns `null` if pending.
  Future<Map<String, dynamic>?> getTransactionReceipt(
    String rpcUrl,
    String txHash,
  ) async {
    final result = await call(
      rpcUrl,
      'eth_getTransactionReceipt',
      [txHash],
    );
    return result as Map<String, dynamic>?;
  }

  /// Closes the underlying HTTP client.
  void dispose() => _client.close();
}
