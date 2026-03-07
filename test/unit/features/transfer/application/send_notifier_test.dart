import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/application/send_notifier.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';

void main() {
  group('SendNotifier', () {
    late SendNotifier notifier;

    setUp(() {
      notifier = SendNotifier();
    });

    test('initial state is empty', () {
      expect(notifier.state.toAddress, '');
      expect(notifier.state.amount, '');
    });

    test('setAddress validates correct address', () {
      notifier.setAddress('0x1234567890123456789012345678901234567890');
      expect(notifier.state.toAddress, '0x1234567890123456789012345678901234567890');
      expect(notifier.state.addressError, isNull);
    });

    test('setAddress validates incorrect address', () {
      notifier.setAddress('0xinvalid');
      expect(notifier.state.addressError, isNotNull);
    });

    test('setAddress validates empty address', () {
      notifier.setAddress('');
      expect(notifier.state.addressError, isNull);
      expect(notifier.state.toAddress, '');
    });

    test('setAmount validates correct amount', () {
      notifier.setAmount('1.5');
      expect(notifier.state.amount, '1.5');
      expect(notifier.state.amountError, isNull);
    });

    test('setAmount validates zero amount', () {
      notifier.setAmount('0');
      expect(notifier.state.amountError, isNotNull);
    });

    test('setAmount validates negative amount', () {
      notifier.setAmount('-1');
      expect(notifier.state.amountError, isNotNull);
    });

    test('setAmount validates non-numeric', () {
      notifier.setAmount('abc');
      expect(notifier.state.amountError, isNotNull);
    });

    test('setGasTier updates selection', () {
      notifier.setGasTier(GasTierSelection.fast);
      expect(notifier.state.selectedTier, GasTierSelection.fast);
    });

    test('setMaxAmount sets amount and clears error', () {
      notifier.setMaxAmount('10.5');
      expect(notifier.state.amount, '10.5');
      expect(notifier.state.amountError, isNull);
    });

    test('reset clears all fields', () {
      notifier.setAddress('0x1234567890123456789012345678901234567890');
      notifier.setAmount('1.0');
      notifier.setGasTier(GasTierSelection.fast);
      notifier.reset();
      expect(notifier.state.toAddress, '');
      expect(notifier.state.amount, '');
      expect(notifier.state.selectedTier, GasTierSelection.standard);
    });
  });
}
