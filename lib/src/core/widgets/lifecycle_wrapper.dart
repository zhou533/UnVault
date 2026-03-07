import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/services/app_lifecycle_service.dart';
import 'package:unvault/src/core/services/clipboard_security_service.dart';
import 'package:unvault/src/core/widgets/privacy_overlay.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';

part 'lifecycle_wrapper.g.dart';

@Riverpod(keepAlive: true)
AppLifecycleService appLifecycleService(Ref ref) {
  return AppLifecycleService();
}

@Riverpod(keepAlive: true)
ClipboardSecurityService clipboardSecurityService(Ref ref) {
  return ClipboardSecurityService();
}

/// Wraps child widget with lifecycle observation for auto-lock and privacy overlay.
class LifecycleWrapper extends ConsumerStatefulWidget {
  const LifecycleWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LifecycleWrapper> createState() => _LifecycleWrapperState();
}

class _LifecycleWrapperState extends ConsumerState<LifecycleWrapper>
    with WidgetsBindingObserver {
  bool _showPrivacyOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lifecycleService = ref.read(appLifecycleServiceProvider);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        lifecycleService.recordBackgroundTimestamp();
        ref.read(clipboardSecurityServiceProvider).clearNow();
        setState(() => _showPrivacyOverlay = true);

      case AppLifecycleState.resumed:
        setState(() => _showPrivacyOverlay = false);
        if (lifecycleService.shouldLock()) {
          ref.read(authProvider.notifier).lock();
        }
        lifecycleService.clearBackgroundTimestamp();

      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPrivacyOverlay)
          const Positioned.fill(child: PrivacyOverlay()),
      ],
    );
  }
}
