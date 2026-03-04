import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  /// App just launched, checking storage.
  const factory AuthState.loading() = _Loading;

  /// First launch — no wallet exists yet.
  const factory AuthState.firstLaunch() = _FirstLaunch;

  /// Wallet exists, waiting for password.
  const factory AuthState.locked() = _Locked;

  /// Successfully authenticated.
  const factory AuthState.unlocked() = _Unlocked;

  /// Authentication failed.
  const factory AuthState.error(String message) = _Error;
}
