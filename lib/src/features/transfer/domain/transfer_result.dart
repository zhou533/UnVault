class TransferResult {
  const TransferResult._({
    required this.isSuccess,
    this.txHash,
    this.errorMessage,
  });

  factory TransferResult.success({required String txHash}) {
    return TransferResult._(isSuccess: true, txHash: txHash);
  }

  factory TransferResult.failure({required String errorMessage}) {
    return TransferResult._(isSuccess: false, errorMessage: errorMessage);
  }

  final bool isSuccess;
  final String? txHash;
  final String? errorMessage;
}
