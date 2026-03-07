import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/services/rpc_client.dart';
import 'package:unvault/src/features/transfer/domain/gas_estimate.dart';

class GasService {
  const GasService({required this.rpcClient});

  final RpcClient rpcClient;

  static const _simpleTransferGas = 21000;

  Future<GasEstimate> estimate({
    required ChainConfig chain,
    required String from,
    required String to,
    required BigInt value,
  }) async {
    final rawGasLimit = await rpcClient.estimateGas({
      'from': from,
      'to': to,
      'value': '0x${value.toRadixString(16)}',
    });

    // Add 20% buffer for non-simple transfers
    final gasLimit = rawGasLimit.toInt() == _simpleTransferGas
        ? rawGasLimit
        : rawGasLimit * BigInt.from(120) ~/ BigInt.from(100);

    if (chain.gasType == GasType.eip1559) {
      return _estimateEip1559(gasLimit);
    } else {
      return _estimateLegacy(gasLimit);
    }
  }

  Future<GasEstimate> _estimateEip1559(BigInt gasLimit) async {
    final feeHistory = await rpcClient.getFeeHistory(4, 'latest', [25, 50, 75]);

    final baseFees = (feeHistory['baseFeePerGas'] as List)
        .map((e) => BigInt.parse(e as String))
        .toList();
    final latestBaseFee = baseFees.last;

    final rewards = feeHistory['reward'] as List;
    final slowTips = <BigInt>[];
    final standardTips = <BigInt>[];
    final fastTips = <BigInt>[];

    for (final block in rewards) {
      final blockRewards = (block as List).map((e) => BigInt.parse(e as String)).toList();
      slowTips.add(blockRewards[0]);
      standardTips.add(blockRewards[1]);
      fastTips.add(blockRewards[2]);
    }

    final slowPriority = _median(slowTips);
    final standardPriority = _median(standardTips);
    final fastPriority = _median(fastTips);

    final slowMaxFee = latestBaseFee + slowPriority;
    final standardMaxFee = latestBaseFee + standardPriority;
    final fastMaxFee = latestBaseFee + fastPriority;

    return GasEstimate(
      gasLimit: gasLimit,
      slow: GasTier(
        label: 'Slow',
        maxFeePerGas: slowMaxFee,
        maxPriorityFeePerGas: slowPriority,
        gasPrice: null,
        estimatedTime: const Duration(minutes: 2),
        totalCostWei: gasLimit * slowMaxFee,
      ),
      standard: GasTier(
        label: 'Standard',
        maxFeePerGas: standardMaxFee,
        maxPriorityFeePerGas: standardPriority,
        gasPrice: null,
        estimatedTime: const Duration(seconds: 30),
        totalCostWei: gasLimit * standardMaxFee,
      ),
      fast: GasTier(
        label: 'Fast',
        maxFeePerGas: fastMaxFee,
        maxPriorityFeePerGas: fastPriority,
        gasPrice: null,
        estimatedTime: const Duration(seconds: 12),
        totalCostWei: gasLimit * fastMaxFee,
      ),
    );
  }

  Future<GasEstimate> _estimateLegacy(BigInt gasLimit) async {
    final baseGasPrice = await rpcClient.getGasPrice();

    final slowPrice = baseGasPrice * BigInt.from(90) ~/ BigInt.from(100);
    final fastPrice = baseGasPrice * BigInt.from(120) ~/ BigInt.from(100);

    return GasEstimate(
      gasLimit: gasLimit,
      slow: GasTier(
        label: 'Slow',
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
        gasPrice: slowPrice,
        estimatedTime: const Duration(minutes: 2),
        totalCostWei: gasLimit * slowPrice,
      ),
      standard: GasTier(
        label: 'Standard',
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
        gasPrice: baseGasPrice,
        estimatedTime: const Duration(seconds: 30),
        totalCostWei: gasLimit * baseGasPrice,
      ),
      fast: GasTier(
        label: 'Fast',
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
        gasPrice: fastPrice,
        estimatedTime: const Duration(seconds: 12),
        totalCostWei: gasLimit * fastPrice,
      ),
    );
  }

  BigInt _median(List<BigInt> values) {
    final sorted = List<BigInt>.from(values)..sort();
    return sorted[sorted.length ~/ 2];
  }
}
