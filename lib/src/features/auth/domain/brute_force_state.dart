import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'brute_force_state.freezed.dart';

@freezed
sealed class BruteForceState with _$BruteForceState {
  const BruteForceState._();

  const factory BruteForceState({
    required int failedAttempts,
    required DateTime? lockoutUntil,
  }) = _BruteForceState;

  static const BruteForceState initial = BruteForceState(
    failedAttempts: 0,
    lockoutUntil: null,
  );

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  int get remainingAttempts => max(0, 10 - failedAttempts);
}

/// Delay sequence: [0, 1, 2, 4, 8, 16, 32, 60, 120] seconds for attempts 1-9.
/// Returns null for attempt >= 10 (full lockout instead).
Duration? delayForAttempt(int attempt) {
  if (attempt <= 0) return Duration.zero;
  if (attempt >= 10) return null;
  const delays = [0, 1, 2, 4, 8, 16, 32, 60, 120];
  return Duration(seconds: delays[attempt - 1]);
}
