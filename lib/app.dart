import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unvault/src/core/services/device_security_check.dart';
import 'package:unvault/src/core/widgets/lifecycle_wrapper.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/localization/generated/app_localizations.dart';
import 'package:unvault/src/routing/app_router.dart';

/// Global navigator key shared between GoRouter and app-level dialogs.
final rootNavigatorKey = GlobalKey<NavigatorState>();

class UnVaultApp extends ConsumerStatefulWidget {
  const UnVaultApp({super.key});

  @override
  ConsumerState<UnVaultApp> createState() => _UnVaultAppState();
}

class _UnVaultAppState extends ConsumerState<UnVaultApp> {
  bool _securityCheckDone = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Trigger auth state check after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthState();
      _runDeviceSecurityCheck();
    });

    return LifecycleWrapper(
      child: MaterialApp.router(
      title: 'UnVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
    );
  }

  void _runDeviceSecurityCheck() {
    if (_securityCheckDone) return;
    _securityCheckDone = true;

    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      const DeviceSecurityCheck().runCheck(ctx);
    }
  }
}
