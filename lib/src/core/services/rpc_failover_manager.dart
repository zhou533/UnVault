import 'package:http/http.dart' as http;
import 'package:unvault/src/core/services/rpc_client.dart';

/// Manages RPC failover across multiple URLs with retry logic.
///
/// - Retries on same URL up to [maxRetries] times with exponential backoff.
/// - On exhaustion, fails over to the next URL in the list.
/// - Throws [RpcException] when all URLs are exhausted.
class RpcFailoverManager {
  RpcFailoverManager({
    required this.rpcUrls,
    this.maxRetries = 3,
    this.baseRetryDelay = const Duration(seconds: 1),
    http.Client Function(String url)? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? ((_) => http.Client());

  final List<String> rpcUrls;
  final int maxRetries;
  final Duration baseRetryDelay;
  final http.Client Function(String url) _httpClientFactory;

  /// Execute an RPC action with automatic retry and failover.
  Future<T> execute<T>(Future<T> Function(RpcClient client) action) async {
    RpcException? lastError;

    for (final url in rpcUrls) {
      final client = RpcClient(
        url: url,
        httpClient: _httpClientFactory(url),
      );

      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          return await action(client);
        } on RpcException catch (e) {
          lastError = e;
          if (attempt < maxRetries - 1 &&
              baseRetryDelay > Duration.zero) {
            await Future<void>.delayed(
              baseRetryDelay * (1 << attempt),
            );
          }
        }
      }
    }

    throw lastError ?? const RpcException('All RPC endpoints exhausted');
  }
}
