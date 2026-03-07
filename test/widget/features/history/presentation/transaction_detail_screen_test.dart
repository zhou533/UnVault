import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';
import 'package:unvault/src/features/history/presentation/transaction_detail_screen.dart';

void main() {
  Widget buildScreen(TransactionRecord record) {
    return MaterialApp(
      home: TransactionDetailScreen(record: record),
    );
  }

  testWidgets('displays tx hash', (tester) async {
    final record = TransactionRecord(
      txHash: '0xabcdef1234567890',
      from: '0xSender',
      to: '0xReceiver',
      value: BigInt.from(1000000000000000000),
      chainId: 1,
      status: TransactionStatus.confirmed,
      timestamp: DateTime(2026, 1, 1),
      nonce: 5,
      blockNumber: 12345,
      gasUsed: BigInt.from(21000),
      gasPrice: BigInt.from(20000000000),
    );

    await tester.pumpWidget(buildScreen(record));

    expect(find.textContaining('0xabcdef'), findsWidgets);
  });

  testWidgets('displays from and to addresses', (tester) async {
    final record = TransactionRecord(
      txHash: '0xabc',
      from: '0xSenderAddr',
      to: '0xReceiverAddr',
      value: BigInt.zero,
      chainId: 1,
      status: TransactionStatus.confirmed,
      timestamp: DateTime(2026, 1, 1),
      nonce: 0,
    );

    await tester.pumpWidget(buildScreen(record));

    expect(find.textContaining('0xSenderAddr'), findsWidgets);
    expect(find.textContaining('0xReceiverAddr'), findsWidgets);
  });

  testWidgets('displays status', (tester) async {
    final record = TransactionRecord(
      txHash: '0xabc',
      from: '0xA',
      to: '0xB',
      value: BigInt.zero,
      chainId: 1,
      status: TransactionStatus.failed,
      timestamp: DateTime(2026, 1, 1),
      nonce: 0,
    );

    await tester.pumpWidget(buildScreen(record));

    expect(find.textContaining('Failed'), findsWidgets);
  });

  testWidgets('displays block number when present', (tester) async {
    final record = TransactionRecord(
      txHash: '0xabc',
      from: '0xA',
      to: '0xB',
      value: BigInt.zero,
      chainId: 1,
      status: TransactionStatus.confirmed,
      timestamp: DateTime(2026, 1, 1),
      nonce: 0,
      blockNumber: 99999,
    );

    await tester.pumpWidget(buildScreen(record));

    expect(find.textContaining('99999'), findsWidgets);
  });
}
