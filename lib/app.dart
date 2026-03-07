import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unvault/src/core/widgets/lifecycle_wrapper.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/localization/generated/app_localizations.dart';
import 'package:unvault/src/routing/app_router.dart';

class UnVaultApp extends ConsumerWidget {
  const UnVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Trigger auth state check after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuthState();
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
}
