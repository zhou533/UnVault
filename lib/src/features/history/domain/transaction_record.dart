enum TransactionStatus { pending, confirmed, failed }

class TransactionRecord {
  const TransactionRecord({
    required this.txHash,
    required this.from,
    required this.to,
    required this.value,
    required this.chainId,
    required this.status,
    required this.timestamp,
    required this.nonce,
    this.gasUsed,
    this.gasPrice,
    this.blockNumber,
  });

  final String txHash;
  final String from;
  final String to;
  final BigInt value;
  final int chainId;
  final TransactionStatus status;
  final DateTime timestamp;
  final int nonce;
  final BigInt? gasUsed;
  final BigInt? gasPrice;
  final int? blockNumber;

  bool isSent(String address) => from == address;
}
