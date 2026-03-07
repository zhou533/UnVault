import 'dart:async';

import 'package:flutter/services.dart';

/// Manages secure clipboard operations with auto-clear.
///
/// - Copies content with 60-second auto-clear timer.
/// - Only clears if clipboard still contains our content (not modified externally).
/// - Provides clearNow() for immediate clear (e.g., on app background).
class ClipboardSecurityService {
  static const _clearDuration = Duration(seconds: 60);

  Timer? _clearTimer;
  String? _lastCopiedContent;

  bool get hasPendingClear => _clearTimer?.isActive ?? false;

  /// Copy content to clipboard with auto-clear after 60 seconds.
  Future<void> secureCopy(String content) async {
    _lastCopiedContent = content;
    await Clipboard.setData(ClipboardData(text: content));
    _clearTimer?.cancel();
    _clearTimer = Timer(_clearDuration, () => _clearIfOurs());
  }

  /// Immediately clear clipboard if it still contains our content.
  Future<void> clearNow() async {
    _clearTimer?.cancel();
    _clearTimer = null;
    await _clearIfOurs();
  }

  Future<void> _clearIfOurs() async {
    if (_lastCopiedContent == null) return;
    final data = await Clipboard.getData('text/plain');
    if (data?.text == _lastCopiedContent) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
    _lastCopiedContent = null;
  }

  void dispose() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
