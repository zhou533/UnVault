enum GasTierSelection { slow, standard, fast }

class SendFormState {
  const SendFormState({
    this.toAddress = '',
    this.amount = '',
    this.selectedTier = GasTierSelection.standard,
    this.addressError,
    this.amountError,
  });

  final String toAddress;
  final String amount;
  final GasTierSelection selectedTier;
  final String? addressError;
  final String? amountError;

  bool get isValid =>
      toAddress.isNotEmpty &&
      amount.isNotEmpty &&
      addressError == null &&
      amountError == null;

  SendFormState copyWith({
    String? toAddress,
    String? amount,
    GasTierSelection? selectedTier,
    String? Function()? addressError,
    String? Function()? amountError,
  }) {
    return SendFormState(
      toAddress: toAddress ?? this.toAddress,
      amount: amount ?? this.amount,
      selectedTier: selectedTier ?? this.selectedTier,
      addressError: addressError != null ? addressError() : this.addressError,
      amountError: amountError != null ? amountError() : this.amountError,
    );
  }
}
