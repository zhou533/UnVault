import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/auth_state.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';
import 'package:unvault/src/features/auth/presentation/lock_screen.dart';

import '../../../helpers/pump_app.dart';

class _ErrorAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState.error('Incorrect password');
}

class MockBruteForceRepository extends Mock implements BruteForceRepository {}

void main() {
  late MockBruteForceRepository mockBfRepo;

  setUp(() {
    mockBfRepo = MockBruteForceRepository();
    when(() => mockBfRepo.getState())
        .thenAnswer((_) async => BruteForceState.initial);
  });

  testWidgets(
      'lock screen has password field and unlock button', (tester) async {
    final container = ProviderContainer(
      overrides: [
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );
    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
  });

  testWidgets('shows error message when auth fails', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(_ErrorAuthNotifier.new),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );

    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.text('Incorrect password'), findsOneWidget);
  });

  testWidgets('shows remaining attempts after failures', (tester) async {
    final container = ProviderContainer(
      overrides: [
        bruteForceProvider.overrideWithValue(const BruteForceState(
              failedAttempts: 7,
              lockoutUntil: null,
            )),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );

    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.text('3 attempts remaining'), findsOneWidget);
  });

  testWidgets('disables input and shows lockout banner when locked out',
      (tester) async {
    final lockout = DateTime.now().add(const Duration(minutes: 25));
    final container = ProviderContainer(
      overrides: [
        bruteForceProvider.overrideWithValue(BruteForceState(
              failedAttempts: 10,
              lockoutUntil: lockout,
            )),
        bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
      ],
    );

    await tester.pumpApp(const LockScreen(), container: container);

    expect(find.textContaining('Too many failed attempts'), findsOneWidget);
    // Unlock button should be disabled
    final button =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'));
    expect(button.onPressed, isNull);
  });
}
