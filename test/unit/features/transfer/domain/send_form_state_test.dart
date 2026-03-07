import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';

void main() {
  group('SendFormState', () {
    test('initial state has empty fields and no errors', () {
      const state = SendFormState();
      expect(state.toAddress, '');
      expect(state.amount, '');
      expect(state.selectedTier, GasTierSelection.standard);
      expect(state.addressError, isNull);
      expect(state.amountError, isNull);
      expect(state.isValid, isFalse);
    });

    test('copyWith updates fields', () {
      const state = SendFormState();
      final updated = state.copyWith(
        toAddress: '0x1234567890123456789012345678901234567890',
        amount: '1.5',
      );
      expect(updated.toAddress, '0x1234567890123456789012345678901234567890');
      expect(updated.amount, '1.5');
    });

    test('isValid is true when address and amount set with no errors', () {
      const state = SendFormState(
        toAddress: '0x1234567890123456789012345678901234567890',
        amount: '1.0',
      );
      expect(state.isValid, isTrue);
    });

    test('isValid is false with address error', () {
      const state = SendFormState(
        toAddress: '0xinvalid',
        amount: '1.0',
        addressError: 'Invalid address',
      );
      expect(state.isValid, isFalse);
    });

    test('isValid is false with amount error', () {
      const state = SendFormState(
        toAddress: '0x1234567890123456789012345678901234567890',
        amount: '-1',
        amountError: 'Invalid amount',
      );
      expect(state.isValid, isFalse);
    });

    test('GasTierSelection has three values', () {
      expect(GasTierSelection.values.length, 3);
    });
  });
}
