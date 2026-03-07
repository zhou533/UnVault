import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/network/presentation/add_network_screen.dart';

void main() {
  Widget buildScreen({
    void Function(AddNetworkResult)? onSubmit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AddNetworkScreen(
          onSubmit: onSubmit ?? (_) {},
        ),
      ),
    );
  }

  group('AddNetworkScreen', () {
    testWidgets('shows form fields', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Network Name'), findsOneWidget);
      expect(find.text('RPC URL'), findsOneWidget);
      expect(find.text('Chain ID'), findsOneWidget);
      expect(find.text('Currency Symbol'), findsOneWidget);
      expect(find.text('Block Explorer URL (optional)'), findsOneWidget);
    });

    testWidgets('submit button disabled when fields empty', (tester) async {
      await tester.pumpWidget(buildScreen());

      final button = find.widgetWithText(FilledButton, 'Add Network');
      expect(button, findsOneWidget);

      final widget = tester.widget<FilledButton>(button);
      expect(widget.onPressed, isNull);
    });

    testWidgets('shows warning for non-HTTPS URL', (tester) async {
      await tester.pumpWidget(buildScreen());

      final rpcField = find.widgetWithText(TextFormField, 'RPC URL');
      await tester.enterText(rpcField, 'http://example.com');
      await tester.pump();

      expect(find.textContaining('not using HTTPS'), findsOneWidget);
    });

    testWidgets('calls onSubmit with form data', (tester) async {
      AddNetworkResult? result;
      await tester.pumpWidget(buildScreen(
        onSubmit: (r) => result = r,
      ));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Network Name'), 'My Network');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'RPC URL'), 'https://rpc.test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Chain ID'), '12345');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Currency Symbol'), 'TEST');
      await tester.pump();

      final button = find.widgetWithText(FilledButton, 'Add Network');
      await tester.tap(button);
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.name, 'My Network');
      expect(result!.rpcUrl, 'https://rpc.test.com');
      expect(result!.chainId, 12345);
      expect(result!.symbol, 'TEST');
    });
  });
}
