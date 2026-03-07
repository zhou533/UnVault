import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/widgets/security_warning_dialog.dart';

void main() {
  group('SecurityWarningDialog', () {
    testWidgets('shows warning message and acknowledge button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showSecurityWarningDialog(context: context),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Security Warning'), findsOneWidget);
      expect(find.textContaining('rooted'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);
      expect(find.text("Don't show again"), findsOneWidget);
    });

    testWidgets('returns false when acknowledged without checkbox',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result =
                      await showSecurityWarningDialog(context: context);
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns true when "don\'t show again" is checked',
        (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result =
                      await showSecurityWarningDialog(context: context);
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Don't show again"));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
