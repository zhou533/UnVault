import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/auth/presentation/lock_screen.dart';

import '../../../helpers/pump_app.dart';

class _ErrorAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.error('Incorrect password');
}

void main() {
  testWidgets(
      'lock screen has password field and unlock button', (tester) async {
    await tester.pumpApp(const LockScreen());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('shows error message when auth fails', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_ErrorAuthNotifier.new),
      ],
    );

    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.text('Incorrect password'), findsOneWidget);
  });
}
