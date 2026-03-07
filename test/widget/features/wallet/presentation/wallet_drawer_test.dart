import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
import 'package:unvault/src/features/wallet/presentation/wallet_drawer.dart';

void main() {
  final wallets = [
    WalletModel(
      id: 1,
      name: 'Main Wallet',
      firstAddress: '0xAbC123',
      isBackedUp: true,
      createdAt: DateTime(2026, 1, 1),
    ),
    WalletModel(
      id: 2,
      name: 'Trading',
      firstAddress: '0xDef456',
      isBackedUp: false,
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  Widget buildDrawer({
    required int activeWalletId,
    void Function(int)? onWalletSelected,
    VoidCallback? onAddWallet,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WalletDrawer(
          wallets: wallets,
          activeWalletId: activeWalletId,
          onWalletSelected: onWalletSelected ?? (_) {},
          onAddWallet: onAddWallet ?? () {},
        ),
      ),
    );
  }

  testWidgets('displays all wallet names', (tester) async {
    await tester.pumpWidget(buildDrawer(activeWalletId: 1));

    expect(find.text('Main Wallet'), findsOneWidget);
    expect(find.text('Trading'), findsOneWidget);
  });

  testWidgets('shows check icon on active wallet', (tester) async {
    await tester.pumpWidget(buildDrawer(activeWalletId: 1));

    // Active wallet should have a check icon
    final mainTile = find.ancestor(
      of: find.text('Main Wallet'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: mainTile, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
  });

  testWidgets('shows warning icon for unbackedup wallet', (tester) async {
    await tester.pumpWidget(buildDrawer(activeWalletId: 1));

    final tradingTile = find.ancestor(
      of: find.text('Trading'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: tradingTile, matching: find.byIcon(Icons.warning)),
      findsOneWidget,
    );
  });

  testWidgets('calls onWalletSelected when non-active wallet tapped',
      (tester) async {
    int? selectedId;
    await tester.pumpWidget(buildDrawer(
      activeWalletId: 1,
      onWalletSelected: (id) => selectedId = id,
    ));

    await tester.tap(find.text('Trading'));
    expect(selectedId, 2);
  });

  testWidgets('has add wallet button', (tester) async {
    bool addCalled = false;
    await tester.pumpWidget(buildDrawer(
      activeWalletId: 1,
      onAddWallet: () => addCalled = true,
    ));

    final addButton = find.text('Add Wallet');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    expect(addCalled, isTrue);
  });

  testWidgets('shows wallet count', (tester) async {
    await tester.pumpWidget(buildDrawer(activeWalletId: 1));

    expect(find.textContaining('2'), findsWidgets);
  });
}
