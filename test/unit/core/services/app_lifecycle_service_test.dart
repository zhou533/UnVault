import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/services/app_lifecycle_service.dart';

void main() {
  group('AppLifecycleService', () {
    test('shouldLock returns false within timeout', () {
      final service = AppLifecycleService(
        lockTimeout: const Duration(seconds: 30),
      );

      service.recordBackgroundTimestamp();
      // Immediately check — should not lock
      expect(service.shouldLock(), isFalse);
    });

    test('shouldLock returns true after timeout', () {
      final service = AppLifecycleService(
        lockTimeout: Duration.zero, // immediate lock
      );

      service.recordBackgroundTimestamp();
      expect(service.shouldLock(), isTrue);
    });

    test('shouldLock returns true if no background timestamp recorded', () {
      final service = AppLifecycleService(
        lockTimeout: const Duration(seconds: 30),
      );

      // Process killed scenario — no timestamp, should lock
      expect(service.shouldLock(), isTrue);
    });

    test('lockTimeout can be updated', () {
      final service = AppLifecycleService(
        lockTimeout: const Duration(minutes: 5),
      );

      service.lockTimeout = const Duration(seconds: 0);
      service.recordBackgroundTimestamp();
      expect(service.shouldLock(), isTrue);
    });

    test('clearBackgroundTimestamp prevents lock on resume', () {
      final service = AppLifecycleService(
        lockTimeout: Duration.zero,
      );

      service.recordBackgroundTimestamp();
      service.clearBackgroundTimestamp();
      // After clear, shouldLock returns true (no timestamp = process killed)
      expect(service.shouldLock(), isTrue);
    });
  });

  group('lockTimeoutFromIndex', () {
    test('index 0 is immediate', () {
      expect(lockTimeoutFromIndex(0), Duration.zero);
    });

    test('index 1 is 30 seconds', () {
      expect(lockTimeoutFromIndex(1), const Duration(seconds: 30));
    });

    test('index 2 is 1 minute', () {
      expect(lockTimeoutFromIndex(2), const Duration(minutes: 1));
    });

    test('index 3 is 5 minutes', () {
      expect(lockTimeoutFromIndex(3), const Duration(minutes: 5));
    });

    test('invalid index defaults to 30 seconds', () {
      expect(lockTimeoutFromIndex(99), const Duration(seconds: 30));
    });
  });
}
