import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_wallet_notifier.g.dart';

/// Tracks the currently selected wallet ID and account ID.
@Riverpod(keepAlive: true)
class ActiveWallet extends _$ActiveWallet {
  @override
  ({int walletId, int accountId}) build() =>
      (walletId: 0, accountId: 0);

  void setWallet(int walletId, int accountId) =>
      state = (walletId: walletId, accountId: accountId);

  void setAccount(int accountId) =>
      state = (walletId: state.walletId, accountId: accountId);
}
