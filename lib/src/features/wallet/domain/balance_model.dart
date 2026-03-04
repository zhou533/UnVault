import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance_model.freezed.dart';

/// Represents the native token balance for a single chain.
@freezed
abstract class TokenBalance with _$TokenBalance {
  const factory TokenBalance({
    required String symbol,
    required String chainName,
    required int chainId,
    required BigInt balanceWei,
    required int decimals,
  }) = _TokenBalance;
}
