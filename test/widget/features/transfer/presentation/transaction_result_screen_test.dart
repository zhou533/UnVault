import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/presentation/transaction_result_screen.dart';

void main() {
  group('TransactionResultScreen', () {
    group('success state', () {
      Widget buildSuccess({
        String txHash = '0xabc123def456789012345678901234567890123456789012345678901234abcd',
        String explorerUrl = 'https://etherscan.io',
        String chainName = 'Ethereum',
      }) {
        return MaterialApp(
          home: TransactionResultScreen(
            isSuccess: true,
            txHash: txHash,
            explorerUrl: explorerUrl,
            chainName: chainName,
          ),
        );
      }

      testWidgets('shows success icon', (tester) async {
        await tester.pumpWidget(buildSuccess());

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('shows success title', (tester) async {
        await tester.pumpWidget(buildSuccess());

        expect(find.text('Transaction Sent'), findsOneWidget);
      });

      testWidgets('displays tx hash', (tester) async {
        await tester.pumpWidget(buildSuccess());

        expect(
          find.text(
              '0xabc123def456789012345678901234567890123456789012345678901234abcd'),
          findsOneWidget,
        );
      });

      testWidgets('has view on explorer button', (tester) async {
        await tester.pumpWidget(buildSuccess());

        expect(
          find.widgetWithText(OutlinedButton, 'View on Explorer'),
          findsOneWidget,
        );
      });

      testWidgets('has done button', (tester) async {
        await tester.pumpWidget(buildSuccess());

        expect(
          find.widgetWithText(FilledButton, 'Done'),
          findsOneWidget,
        );
      });

      testWidgets('displays chain name', (tester) async {
        await tester.pumpWidget(buildSuccess(chainName: 'Polygon'));

        expect(find.text('Polygon'), findsOneWidget);
      });
    });

    group('failure state', () {
      Widget buildFailure({
        String errorMessage = 'insufficient funds for gas',
      }) {
        return MaterialApp(
          home: TransactionResultScreen(
            isSuccess: false,
            errorMessage: errorMessage,
            chainName: 'Ethereum',
          ),
        );
      }

      testWidgets('shows error icon', (tester) async {
        await tester.pumpWidget(buildFailure());

        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('shows failure title', (tester) async {
        await tester.pumpWidget(buildFailure());

        expect(find.text('Transaction Failed'), findsOneWidget);
      });

      testWidgets('displays error message', (tester) async {
        await tester.pumpWidget(buildFailure());

        expect(find.text('insufficient funds for gas'), findsOneWidget);
      });

      testWidgets('has retry button', (tester) async {
        await tester.pumpWidget(buildFailure());

        expect(
          find.widgetWithText(FilledButton, 'Try Again'),
          findsOneWidget,
        );
      });
    });
  });
}
