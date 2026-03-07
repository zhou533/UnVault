class GasTier {
  const GasTier({
    required this.label,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.gasPrice,
    required this.estimatedTime,
    required this.totalCostWei,
  });

  final String label;
  final BigInt maxFeePerGas;
  final BigInt maxPriorityFeePerGas;
  final BigInt? gasPrice;
  final Duration estimatedTime;
  final BigInt totalCostWei;
}

class GasEstimate {
  const GasEstimate({
    required this.gasLimit,
    required this.slow,
    required this.standard,
    required this.fast,
  });

  final BigInt gasLimit;
  final GasTier slow;
  final GasTier standard;
  final GasTier fast;
}
