import 'package:flutter/material.dart';
import 'package:unvault/src/core/services/screen_security_service.dart';

/// Wraps a child widget with screenshot/screen recording protection.
/// Enables protection on init, disables on dispose.
class ScreenSecurityWrapper extends StatefulWidget {
  const ScreenSecurityWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<ScreenSecurityWrapper> createState() => _ScreenSecurityWrapperState();
}

class _ScreenSecurityWrapperState extends State<ScreenSecurityWrapper> {
  static const _service = ScreenSecurityService();

  @override
  void initState() {
    super.initState();
    _service.enableProtection();
  }

  @override
  void dispose() {
    _service.disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
