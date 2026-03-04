import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_form_state.freezed.dart';

/// Speed tier for EIP-1559 gas fee selection.
enum GasTier { slow, standard, fast }

/// Immutable state for the send-transaction form.
@freezed
abstract class SendFormState with _$SendFormState {
  const factory SendFormState({
    @Default('') String toAddress,
    @Default('') String amount,
    @Default(GasTier.standard) GasTier gasTier,
    BigInt? estimatedGasWei,
    BigInt? baseFee,
    BigInt? priorityFee,
    String? error,
    @Default(false) bool isEstimating,
  }) = _SendFormState;
}
