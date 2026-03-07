import 'package:flutter/widgets.dart';

/// Lock timeout options: [Immediate, 30s (default), 1min, 5min]
Duration lockTimeoutFromIndex(int index) {
  const options = [
    Duration.zero,
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];
  if (index < 0 || index >= options.length) return options[1]; // default 30s
  return options[index];
}

/// Tracks app lifecycle transitions for auto-lock behavior.
///
/// Records when the app goes to background and determines whether
/// the wallet should be locked when returning to foreground.
class AppLifecycleService {
  AppLifecycleService({
    Duration lockTimeout = const Duration(seconds: 30),
  }) : _lockTimeout = lockTimeout;

  Duration _lockTimeout;
  DateTime? _backgroundTimestamp;

  Duration get lockTimeout => _lockTimeout;
  set lockTimeout(Duration value) => _lockTimeout = value;

  /// Record the moment the app enters background.
  void recordBackgroundTimestamp() {
    _backgroundTimestamp = DateTime.now();
  }

  /// Clear background timestamp (e.g., after successful resume without lock).
  void clearBackgroundTimestamp() {
    _backgroundTimestamp = null;
  }

  /// Determine if the wallet should be locked on resume.
  ///
  /// Returns true if:
  /// - No background timestamp (process was killed and restarted)
  /// - Time elapsed since background exceeds lockTimeout
  bool shouldLock() {
    if (_backgroundTimestamp == null) return true;

    final elapsed = DateTime.now().difference(_backgroundTimestamp!);
    return elapsed >= _lockTimeout;
  }
}
