import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/settings/presentation/security_settings_screen.dart';

void main() {
  Widget buildScreen({
    bool biometricEnabled = false,
    bool biometricAvailable = true,
    String autoLockLabel = '30 seconds',
    void Function(bool)? onBiometricChanged,
    VoidCallback? onAutoLockTap,
    VoidCallback? onViewMnemonicTap,
  }) {
    return MaterialApp(
      home: SecuritySettingsScreen(
        biometricEnabled: biometricEnabled,
        biometricAvailable: biometricAvailable,
        autoLockLabel: autoLockLabel,
        onBiometricChanged: onBiometricChanged ?? (_) {},
        onAutoLockTap: onAutoLockTap ?? () {},
        onViewMnemonicTap: onViewMnemonicTap ?? () {},
      ),
    );
  }

  group('SecuritySettingsScreen', () {
    testWidgets('shows biometric toggle', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Biometric Unlock'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('disables biometric when unavailable', (tester) async {
      await tester.pumpWidget(buildScreen(biometricAvailable: false));

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.onChanged, isNull);
    });

    testWidgets('shows auto-lock setting', (tester) async {
      await tester.pumpWidget(buildScreen(autoLockLabel: '5 minutes'));

      expect(find.text('Auto-Lock Timer'), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
    });

    testWidgets('shows view recovery phrase option', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('View Recovery Phrase'), findsOneWidget);
    });

    testWidgets('tapping view mnemonic fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildScreen(
        onViewMnemonicTap: () => tapped = true,
      ));

      await tester.tap(find.text('View Recovery Phrase'));
      expect(tapped, isTrue);
    });
  });
}
