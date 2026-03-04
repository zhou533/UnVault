/// Immutable representation of a transaction for the UI layer.
///
/// This decouples the presentation layer from drift's generated
/// data class, allowing riverpod codegen to resolve the return type
/// correctly.
class TransactionModel {
  const TransactionModel({
    required this.hash,
    required this.fromAddress,
    required this.value,
    required this.chainId,
    required this.status,
    required this.timestamp,
    this.toAddress,
  });

  final String hash;
  final String fromAddress;
  final String? toAddress;
  final String value;
  final int chainId;
  final String status;
  final DateTime timestamp;
}
