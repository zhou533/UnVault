import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';
import 'package:unvault/src/features/history/presentation/history_list_tile.dart';

void main() {
  group('HistoryListTile', () {
    Widget buildTile(TransactionRecord record, {String myAddress = '0xMe'}) {
      return MaterialApp(
        home: Scaffold(
          body: HistoryListTile(record: record, myAddress: myAddress),
        ),
      );
    }

    testWidgets('shows Sent for outgoing transaction', (tester) async {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0xMe',
        to: '0xOther',
        value: BigInt.from(1000000000000000000), // 1 ETH
        chainId: 1,
        status: TransactionStatus.confirmed,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      await tester.pumpWidget(buildTile(record));

      expect(find.text('Sent'), findsOneWidget);
    });

    testWidgets('shows Received for incoming transaction', (tester) async {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0xOther',
        to: '0xMe',
        value: BigInt.from(1000000000000000000),
        chainId: 1,
        status: TransactionStatus.confirmed,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      await tester.pumpWidget(buildTile(record));

      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets('shows pending indicator for pending tx', (tester) async {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0xMe',
        to: '0xOther',
        value: BigInt.from(100),
        chainId: 1,
        status: TransactionStatus.pending,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      await tester.pumpWidget(buildTile(record));

      expect(find.textContaining('Pending'), findsWidgets);
    });

    testWidgets('shows truncated address', (tester) async {
      final record = TransactionRecord(
        txHash: '0xabc',
        from: '0xMe',
        to: '0x1234567890abcdef1234567890abcdef12345678',
        value: BigInt.from(100),
        chainId: 1,
        status: TransactionStatus.confirmed,
        timestamp: DateTime(2026, 1, 1),
        nonce: 0,
      );

      await tester.pumpWidget(buildTile(record));

      // Should show truncated to address
      expect(find.textContaining('0x1234'), findsWidgets);
    });
  });
}
