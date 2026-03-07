import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';
import 'package:unvault/src/features/history/presentation/widgets/history_filter_bar.dart';

void main() {
  Widget buildBar({
    HistoryFilter? filter,
    void Function(HistoryFilter)? onFilterChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HistoryFilterBar(
          filter: filter ?? const HistoryFilter(),
          onFilterChanged: onFilterChanged ?? (_) {},
        ),
      ),
    );
  }

  group('HistoryFilterBar', () {
    testWidgets('shows filter chips for type', (tester) async {
      await tester.pumpWidget(buildBar());

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets('tapping Sent chip updates filter', (tester) async {
      HistoryFilter? received;
      await tester.pumpWidget(buildBar(
        onFilterChanged: (f) => received = f,
      ));

      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();

      expect(received?.type, HistoryFilterType.sent);
    });

    testWidgets('has search field', (tester) async {
      await tester.pumpWidget(buildBar());

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('search field updates filter query', (tester) async {
      HistoryFilter? received;
      await tester.pumpWidget(buildBar(
        onFilterChanged: (f) => received = f,
      ));

      await tester.enterText(find.byType(TextField), '0xabc');
      await tester.pumpAndSettle();

      expect(received?.searchQuery, '0xabc');
    });

    testWidgets('status filter chips exist', (tester) async {
      await tester.pumpWidget(buildBar());

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
    });
  });
}
