import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

void main() {
  group('TransactionRecord', () {
    test('creates with required fields', () {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0x1111',
        to: '0x2222',
        value: BigInt.from(1000000),
        chainId: 1,
        status: TransactionStatus.confirmed,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      expect(record.txHash, '0xabc');
      expect(record.from, '0x1111');
      expect(record.to, '0x2222');
      expect(record.value, BigInt.from(1000000));
      expect(record.chainId, 1);
      expect(record.status, TransactionStatus.confirmed);
      expect(record.nonce, 0);
    });

    test('nullable fields default to null', () {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0x1111',
        to: '0x2222',
        value: BigInt.zero,
        chainId: 1,
        status: TransactionStatus.pending,
        timestamp: DateTime(2026, 1, 1),
        nonce: 5,
      );

      expect(record.gasUsed, isNull);
      expect(record.gasPrice, isNull);
      expect(record.blockNumber, isNull);
    });

    test('TransactionStatus has pending, confirmed, failed', () {
      expect(TransactionStatus.values, containsAll([
        TransactionStatus.pending,
        TransactionStatus.confirmed,
        TransactionStatus.failed,
      ]));
    });

    test('isSent returns true when from matches address', () {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0xMyAddr',
        to: '0xOther',
        value: BigInt.from(100),
        chainId: 1,
        status: TransactionStatus.confirmed,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      expect(record.isSent('0xMyAddr'), isTrue);
      expect(record.isSent('0xOther'), isFalse);
    });
  });
}
