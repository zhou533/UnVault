import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:unvault/src/features/transfer/presentation/receive_screen.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/qr_display.dart';

void main() {
  group('QrDisplay', () {
    testWidgets('renders QR code with given data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrDisplay(data: '0x1234567890abcdef1234567890abcdef12345678'),
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('applies specified size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QrDisplay(
              data: '0xaddr',
              size: 200,
            ),
          ),
        ),
      );

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 200);
    });
  });

  group('ReceiveScreen', () {
    const testAddress = '0x1234567890abcdef1234567890abcdef12345678';

    Widget buildScreen({
      String address = testAddress,
      String chainName = 'Ethereum',
      String symbol = 'ETH',
    }) {
      return MaterialApp(
        home: ReceiveScreen(
          address: address,
          chainName: chainName,
          symbol: symbol,
        ),
      );
    }

    testWidgets('displays chain name banner', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Ethereum'), findsOneWidget);
    });

    testWidgets('displays QR code', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('displays full address', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text(testAddress), findsOneWidget);
    });

    testWidgets('has copy button', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows network warning', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(
        find.textContaining('same network'),
        findsOneWidget,
      );
    });

    testWidgets('displays symbol in warning', (tester) async {
      await tester.pumpWidget(buildScreen(symbol: 'POL', chainName: 'Polygon'));

      expect(find.text('Polygon'), findsOneWidget);
    });
  });
}
