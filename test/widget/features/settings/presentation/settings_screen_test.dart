import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/settings/presentation/settings_screen.dart';

void main() {
  Widget buildScreen({
    bool biometricEnabled = false,
    String autoLockLabel = '30 seconds',
    VoidCallback? onBiometricToggle,
    VoidCallback? onAutoLockTap,
    VoidCallback? onViewMnemonicTap,
    VoidCallback? onNetworkManagementTap,
    VoidCallback? onAboutTap,
  }) {
    return MaterialApp(
      home: SettingsScreen(
        biometricEnabled: biometricEnabled,
        autoLockLabel: autoLockLabel,
        onBiometricToggle: onBiometricToggle ?? () {},
        onAutoLockTap: onAutoLockTap ?? () {},
        onViewMnemonicTap: onViewMnemonicTap ?? () {},
        onNetworkManagementTap: onNetworkManagementTap ?? () {},
        onAboutTap: onAboutTap ?? () {},
      ),
    );
  }

  group('SettingsScreen', () {
    testWidgets('shows security section', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Biometric Unlock'), findsOneWidget);
      expect(find.text('Auto-Lock'), findsOneWidget);
      expect(find.text('View Recovery Phrase'), findsOneWidget);
    });

    testWidgets('shows network section', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Network Management'), findsOneWidget);
    });

    testWidgets('shows about section', (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('biometric switch reflects state', (tester) async {
      await tester.pumpWidget(buildScreen(biometricEnabled: true));

      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      expect(tester.widget<Switch>(switchWidget).value, isTrue);
    });

    testWidgets('auto-lock shows current setting', (tester) async {
      await tester.pumpWidget(buildScreen(autoLockLabel: '1 minute'));

      expect(find.text('1 minute'), findsOneWidget);
    });

    testWidgets('tapping network management fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildScreen(
        onNetworkManagementTap: () => tapped = true,
      ));

      await tester.tap(find.text('Network Management'));
      expect(tapped, isTrue);
    });
  });
}
