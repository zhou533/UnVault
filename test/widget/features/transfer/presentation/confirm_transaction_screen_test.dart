import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/presentation/confirm_transaction_screen.dart';

void main() {
  group('ConfirmTransactionScreen', () {
    Widget buildScreen({
      String fromAddress = '0x1234567890abcdef1234567890abcdef12345678',
      String toAddress = '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
      String amount = '1.5',
      String symbol = 'ETH',
      String gasCost = '0.003150',
      String chainName = 'Ethereum',
    }) {
      return MaterialApp(
        home: ConfirmTransactionScreen(
          fromAddress: fromAddress,
          toAddress: toAddress,
          amount: amount,
          symbol: symbol,
          gasCost: gasCost,
          chainName: chainName,
        ),
      );
    }

    testWidgets('displays from and to addresses in full', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.text('0x1234567890abcdef1234567890abcdef12345678'),
        findsOneWidget,
      );
      expect(
        find.text('0xabcdefabcdefabcdefabcdefabcdefabcdefabcd'),
        findsOneWidget,
      );
    });

    testWidgets('displays amount and symbol', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('1.5 ETH'), findsOneWidget);
    });

    testWidgets('displays gas cost', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('0.003150 ETH'), findsOneWidget);
    });

    testWidgets('displays chain name', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Ethereum'), findsOneWidget);
    });

    testWidgets('has confirm button', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.widgetWithText(FilledButton, 'Confirm & Send'), findsOneWidget);
    });

    testWidgets('shows total cost (amount + gas)', (tester) async {
      await tester.pumpWidget(buildScreen(
        amount: '1.0',
        gasCost: '0.002000',
      ));

      expect(find.text('1.002000 ETH'), findsOneWidget);
    });
  });
}
