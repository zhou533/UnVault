import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/presentation/network_management_screen.dart';

void main() {
  Widget buildScreen({
    List<ChainConfig>? chains,
    List<ChainConfig>? customChains,
    void Function(int chainId)? onDelete,
    VoidCallback? onAddNetwork,
  }) {
    return MaterialApp(
      home: NetworkManagementScreen(
        builtInChains: chains ?? BuiltInChains.all,
        customChains: customChains ?? const [],
        onDeleteCustomChain: onDelete ?? (_) {},
        onAddNetwork: onAddNetwork ?? () {},
      ),
    );
  }

  group('NetworkManagementScreen', () {
    testWidgets('shows built-in chains grouped by mainnet/testnet',
        (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.text('Mainnet'), findsOneWidget);
      expect(find.text('Testnet'), findsOneWidget);
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('Sepolia'), findsOneWidget);
    });

    testWidgets('shows custom chains section when present', (tester) async {
      await tester.pumpWidget(buildScreen(
        customChains: [
          const ChainConfig(
            chainId: 99999,
            name: 'My Custom Chain',
            symbol: 'CUSTOM',
            rpcUrls: ['https://custom.rpc'],
            explorerUrl: 'https://custom.explorer',
          ),
        ],
      ));

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('My Custom Chain'), findsOneWidget);
    });

    testWidgets('has add network FAB', (tester) async {
      VoidCallback? called;
      await tester.pumpWidget(buildScreen(
        onAddNetwork: () => called = () {},
      ));

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
    });

    testWidgets('built-in chains cannot be deleted', (tester) async {
      await tester.pumpWidget(buildScreen());

      // Built-in chains should not have delete icons
      expect(find.byIcon(Icons.delete), findsNothing);
    });
  });
}
