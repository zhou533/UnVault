class TransferRequest {
  const TransferRequest({
    required this.fromAddress,
    required this.toAddress,
    required this.amountWei,
    required this.gasLimit,
    required this.chainId,
    this.maxFeePerGas,
    this.maxPriorityFeePerGas,
    this.gasPrice,
    this.nonce,
  });

  final String fromAddress;
  final String toAddress;
  final BigInt amountWei;
  final BigInt gasLimit;
  final int chainId;
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;
  final BigInt? gasPrice;
  final int? nonce;
}
