import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/widgets/password_confirm_sheet.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/auth/application/brute_force_notifier.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';
import 'package:unvault/src/features/auth/data/brute_force_repository.dart';
import 'package:unvault/src/features/auth/domain/brute_force_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBruteForceRepository extends Mock implements BruteForceRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockBruteForceRepository mockBfRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockBfRepo = MockBruteForceRepository();
    when(() => mockBfRepo.getState())
        .thenAnswer((_) async => BruteForceState.initial);
    when(() => mockBfRepo.recordSuccess())
        .thenAnswer((_) async => BruteForceState.initial);
    when(() => mockBfRepo.recordFailure()).thenAnswer(
      (_) async =>
          const BruteForceState(failedAttempts: 1, lockoutUntil: null),
    );
  });

  group('PasswordConfirmSheet', () {
    testWidgets('shows password field and confirm button', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showPasswordConfirmSheet(
                    context: context,
                    walletId: 1,
                    actionDescription: 'Export mnemonic',
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Export mnemonic'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('returns true on correct password', (tester) async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => true);

      bool? result;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPasswordConfirmSheet(
                    context: context,
                    walletId: 1,
                    actionDescription: 'Export mnemonic',
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'mypassword');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('shows error on wrong password', (tester) async {
      when(
        () => mockAuthRepo.verifyPassword(
          walletId: any(named: 'walletId'),
          passwordBytes: any(named: 'passwordBytes'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          bruteForceRepositoryProvider.overrideWithValue(mockBfRepo),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showPasswordConfirmSheet(
                    context: context,
                    walletId: 1,
                    actionDescription: 'Export mnemonic',
                  );
                },
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wrongpassword');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect password'), findsOneWidget);
    });
  });
}
