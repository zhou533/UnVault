import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/features/transfer/domain/transfer_result.dart';

class TransferRepository {
  const TransferRepository({required this.rpcClient});

  final RpcClient rpcClient;

  Future<TransferResult> broadcastTransaction(String signedRawTx) async {
    try {
      final txHash = await rpcClient.sendRawTransaction(signedRawTx);
      return TransferResult.success(txHash: txHash);
    } on RpcException catch (e) {
      return TransferResult.failure(errorMessage: e.message);
    }
  }

  Future<int> getNonce(String address) async {
    return rpcClient.getTransactionCount(address);
  }
}
