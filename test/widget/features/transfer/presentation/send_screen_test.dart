import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/application/send_notifier.dart';
import 'package:unvault/src/features/transfer/domain/gas_estimate.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/address_input.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/amount_input.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/gas_selector.dart';

void main() {
  group('AddressInput', () {
    testWidgets('renders text field with hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressInput(
              onChanged: (_) {},
              errorText: null,
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Recipient Address'), findsOneWidget);
    });

    testWidgets('shows error text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressInput(
              onChanged: (_) {},
              errorText: 'Invalid address',
            ),
          ),
        ),
      );
      expect(find.text('Invalid address'), findsOneWidget);
    });

    testWidgets('calls onChanged when text entered', (tester) async {
      String? lastValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressInput(
              onChanged: (v) => lastValue = v,
              errorText: null,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '0xabc');
      expect(lastValue, '0xabc');
    });
  });

  group('AmountInput', () {
    testWidgets('renders text field with balance display', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountInput(
              onChanged: (_) {},
              onMaxPressed: () {},
              errorText: null,
              balance: '10.5',
              symbol: 'ETH',
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('10.5'), findsOneWidget);
      expect(find.text('MAX'), findsOneWidget);
    });

    testWidgets('calls onMaxPressed when MAX tapped', (tester) async {
      var maxPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AmountInput(
              onChanged: (_) {},
              onMaxPressed: () => maxPressed = true,
              errorText: null,
              balance: '10.5',
              symbol: 'ETH',
            ),
          ),
        ),
      );
      await tester.tap(find.text('MAX'));
      expect(maxPressed, isTrue);
    });
  });

  group('GasSelector', () {
    final mockEstimate = GasEstimate(
      gasLimit: BigInt.from(21000),
      slow: GasTier(
        label: 'Slow',
        maxFeePerGas: BigInt.from(20000000000),
        maxPriorityFeePerGas: BigInt.from(1000000000),
        gasPrice: null,
        estimatedTime: const Duration(minutes: 2),
        totalCostWei: BigInt.from(420000000000000),
      ),
      standard: GasTier(
        label: 'Standard',
        maxFeePerGas: BigInt.from(30000000000),
        maxPriorityFeePerGas: BigInt.from(1500000000),
        gasPrice: null,
        estimatedTime: const Duration(seconds: 30),
        totalCostWei: BigInt.from(630000000000000),
      ),
      fast: GasTier(
        label: 'Fast',
        maxFeePerGas: BigInt.from(50000000000),
        maxPriorityFeePerGas: BigInt.from(2000000000),
        gasPrice: null,
        estimatedTime: const Duration(seconds: 12),
        totalCostWei: BigInt.from(1050000000000000),
      ),
    );

    testWidgets('displays three tier options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GasSelector(
              estimate: mockEstimate,
              selectedTier: GasTierSelection.standard,
              onTierChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Slow'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
    });

    testWidgets('calls onTierChanged when tier tapped', (tester) async {
      GasTierSelection? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GasSelector(
              estimate: mockEstimate,
              selectedTier: GasTierSelection.standard,
              onTierChanged: (t) => selected = t,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Fast'));
      expect(selected, GasTierSelection.fast);
    });
  });
}
