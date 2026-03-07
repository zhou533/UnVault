import 'package:flutter/foundation.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';

class SendNotifier extends ChangeNotifier {
  SendFormState _state = const SendFormState();

  SendFormState get state => _state;

  static final _addressRegex = RegExp(r'^0x[0-9a-fA-F]{40}$');

  void setAddress(String address) {
    String? error;
    if (address.isNotEmpty && !_addressRegex.hasMatch(address)) {
      error = 'Invalid Ethereum address';
    }
    _state = _state.copyWith(
      toAddress: address,
      addressError: () => error,
    );
    notifyListeners();
  }

  void setAmount(String amount) {
    String? error;
    if (amount.isNotEmpty) {
      final parsed = double.tryParse(amount);
      if (parsed == null) {
        error = 'Invalid amount';
      } else if (parsed <= 0) {
        error = 'Amount must be greater than 0';
      }
    }
    _state = _state.copyWith(
      amount: amount,
      amountError: () => error,
    );
    notifyListeners();
  }

  void setGasTier(GasTierSelection tier) {
    _state = _state.copyWith(selectedTier: tier);
    notifyListeners();
  }

  void setMaxAmount(String maxAmount) {
    _state = _state.copyWith(
      amount: maxAmount,
      amountError: () => null,
    );
    notifyListeners();
  }

  void reset() {
    _state = const SendFormState();
    notifyListeners();
  }
}
