import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/domain/gas_estimate.dart';

void main() {
  group('GasTier', () {
    test('creates with required fields', () {
      final tier = GasTier(
        label: 'Standard',
        maxFeePerGas: BigInt.from(30000000000),
        maxPriorityFeePerGas: BigInt.from(1500000000),
        gasPrice: null,
        estimatedTime: const Duration(seconds: 30),
        totalCostWei: BigInt.from(630000000000000),
      );
      expect(tier.label, 'Standard');
      expect(tier.maxFeePerGas, BigInt.from(30000000000));
      expect(tier.gasPrice, isNull);
    });

    test('supports legacy gas price', () {
      final tier = GasTier(
        label: 'Standard',
        maxFeePerGas: BigInt.zero,
        maxPriorityFeePerGas: BigInt.zero,
        gasPrice: BigInt.from(5000000000),
        estimatedTime: const Duration(seconds: 60),
        totalCostWei: BigInt.from(105000000000000),
      );
      expect(tier.gasPrice, BigInt.from(5000000000));
    });
  });

  group('GasEstimate', () {
    test('creates with three tiers and gas limit', () {
      final estimate = GasEstimate(
        gasLimit: BigInt.from(21000),
        slow: GasTier(
          label: 'Slow',
          maxFeePerGas: BigInt.from(20000000000),
          maxPriorityFeePerGas: BigInt.from(1000000000),
          gasPrice: null,
          estimatedTime: const Duration(minutes: 2),
          totalCostWei: BigInt.from(420000000000000),
        ),
        standard: GasTier(
          label: 'Standard',
          maxFeePerGas: BigInt.from(30000000000),
          maxPriorityFeePerGas: BigInt.from(1500000000),
          gasPrice: null,
          estimatedTime: const Duration(seconds: 30),
          totalCostWei: BigInt.from(630000000000000),
        ),
        fast: GasTier(
          label: 'Fast',
          maxFeePerGas: BigInt.from(50000000000),
          maxPriorityFeePerGas: BigInt.from(2000000000),
          gasPrice: null,
          estimatedTime: const Duration(seconds: 12),
          totalCostWei: BigInt.from(1050000000000000),
        ),
      );
      expect(estimate.gasLimit, BigInt.from(21000));
      expect(estimate.slow.label, 'Slow');
      expect(estimate.standard.label, 'Standard');
      expect(estimate.fast.label, 'Fast');
    });
  });
}
