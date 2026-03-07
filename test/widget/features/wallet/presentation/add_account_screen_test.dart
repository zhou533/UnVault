import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/wallet/presentation/add_account_screen.dart';

void main() {
  Widget buildScreen({
    String walletName = 'Main Wallet',
    int nextIndex = 1,
    void Function(String? name)? onConfirm,
  }) {
    return MaterialApp(
      home: AddAccountScreen(
        walletName: walletName,
        nextIndex: nextIndex,
        onConfirm: onConfirm ?? (_) {},
      ),
    );
  }

  testWidgets('displays wallet name', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.textContaining('Main Wallet'), findsWidgets);
  });

  testWidgets('displays next derivation index', (tester) async {
    await tester.pumpWidget(buildScreen(nextIndex: 3));

    expect(find.textContaining('3'), findsWidgets);
  });

  testWidgets('has optional name field', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('has create button', (tester) async {
    await tester.pumpWidget(buildScreen());

    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('calls onConfirm with name when create tapped', (tester) async {
    String? receivedName;
    await tester.pumpWidget(buildScreen(
      onConfirm: (name) => receivedName = name,
    ));

    await tester.enterText(find.byType(TextField), 'DeFi Account');
    await tester.tap(find.text('Create Account'));

    expect(receivedName, 'DeFi Account');
  });

  testWidgets('calls onConfirm with null when name empty', (tester) async {
    String? receivedName = 'initial';
    await tester.pumpWidget(buildScreen(
      onConfirm: (name) => receivedName = name,
    ));

    await tester.tap(find.text('Create Account'));

    expect(receivedName, isNull);
  });
}
