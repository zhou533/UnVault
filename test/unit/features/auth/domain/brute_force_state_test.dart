import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

void main() {
  group('BruteForceState', () {
    test('initial state has zero failures and no lockout', () {
      const state = BruteForceState.initial;
      expect(state.failedAttempts, 0);
      expect(state.lockoutUntil, isNull);
    });

    test('remainingAttempts decreases with failures', () {
      const state = BruteForceState(failedAttempts: 3, lockoutUntil: null);
      expect(state.remainingAttempts, 7);
    });

    test('remainingAttempts never goes below zero', () {
      const state = BruteForceState(failedAttempts: 15, lockoutUntil: null);
      expect(state.remainingAttempts, 0);
    });

    test('isLockedOut returns true when lockoutUntil is in the future', () {
      final state = BruteForceState(
        failedAttempts: 10,
        lockoutUntil: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(state.isLockedOut, isTrue);
    });

    test('isLockedOut returns false when lockoutUntil is in the past', () {
      final state = BruteForceState(
        failedAttempts: 10,
        lockoutUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(state.isLockedOut, isFalse);
    });

    test('isLockedOut returns false when lockoutUntil is null', () {
      const state = BruteForceState(failedAttempts: 5, lockoutUntil: null);
      expect(state.isLockedOut, isFalse);
    });
  });

  group('delayForAttempt', () {
    test('first failure has no delay', () {
      expect(delayForAttempt(1), Duration.zero);
    });

    test('second failure has 1 second delay', () {
      expect(delayForAttempt(2), const Duration(seconds: 1));
    });

    test('delay sequence matches spec', () {
      final expected = [0, 1, 2, 4, 8, 16, 32, 60, 120];
      for (var i = 0; i < expected.length; i++) {
        expect(
          delayForAttempt(i + 1),
          Duration(seconds: expected[i]),
          reason: 'Attempt ${i + 1} should have ${expected[i]}s delay',
        );
      }
    });

    test('10th failure returns null (lockout instead)', () {
      expect(delayForAttempt(10), isNull);
    });

    test('attempts beyond 10 return null', () {
      expect(delayForAttempt(15), isNull);
    });

    test('zero or negative attempts return zero delay', () {
      expect(delayForAttempt(0), Duration.zero);
      expect(delayForAttempt(-1), Duration.zero);
    });
  });
}
