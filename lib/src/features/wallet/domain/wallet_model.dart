import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.freezed.dart';

@freezed
abstract class WalletModel with _$WalletModel {
  const factory WalletModel({
    required int id,
    required String name,
    required String firstAddress,
    required bool isBackedUp,
    required DateTime createdAt,
  }) = _WalletModel;
}
