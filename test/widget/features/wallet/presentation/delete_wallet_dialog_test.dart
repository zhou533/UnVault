import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/wallet/presentation/delete_wallet_dialog.dart';

void main() {
  Widget buildDialog({
    String walletName = 'Test Wallet',
    Future<bool> Function(String password)? onVerifyPassword,
    void Function()? onConfirmedDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DeleteWalletDialog(
          walletName: walletName,
          onVerifyPassword: onVerifyPassword ?? (_) async => true,
          onConfirmedDelete: onConfirmedDelete ?? () {},
        ),
      ),
    );
  }

  group('Step 1: Initial confirmation', () {
    testWidgets('shows wallet name and delete warning', (tester) async {
      await tester.pumpWidget(buildDialog(walletName: 'My Wallet'));

      expect(find.textContaining('My Wallet'), findsWidgets);
      expect(find.textContaining('delete'), findsWidgets);
    });

    testWidgets('has cancel and continue buttons', (tester) async {
      await tester.pumpWidget(buildDialog());

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('cancel pops without calling onConfirmedDelete',
        (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildDialog(
        onConfirmedDelete: () => deleted = true,
      ));

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
    });
  });

  group('Step 2: Password verification', () {
    testWidgets('continue shows password field', (tester) async {
      await tester.pumpWidget(buildDialog());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('verify button calls onVerifyPassword', (tester) async {
      String? receivedPassword;
      await tester.pumpWidget(buildDialog(
        onVerifyPassword: (pw) async {
          receivedPassword = pw;
          return true;
        },
      ));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mypassword');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(receivedPassword, 'mypassword');
    });

    testWidgets('wrong password shows error', (tester) async {
      await tester.pumpWidget(buildDialog(
        onVerifyPassword: (_) async => false,
      ));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Incorrect'), findsOneWidget);
    });
  });

  group('Step 3: Type DELETE confirmation', () {
    testWidgets('after password, shows DELETE input', (tester) async {
      await tester.pumpWidget(buildDialog());

      // Step 1 -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2 -> Step 3
      await tester.enterText(find.byType(TextField), 'password');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.textContaining('DELETE'), findsWidgets);
    });

    testWidgets('delete button disabled until DELETE typed', (tester) async {
      await tester.pumpWidget(buildDialog());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'password');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Find the delete button - should be disabled
      final deleteButton = find.widgetWithText(FilledButton, 'Delete Wallet');
      expect(deleteButton, findsOneWidget);
      final button = tester.widget<FilledButton>(deleteButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('typing DELETE enables button and calls onConfirmedDelete',
        (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildDialog(
        onConfirmedDelete: () => deleted = true,
      ));

      // Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.enterText(find.byType(TextField), 'password');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      // Step 3
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      final deleteButton = find.widgetWithText(FilledButton, 'Delete Wallet');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });
  });
}
