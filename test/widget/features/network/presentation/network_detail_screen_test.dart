import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/presentation/network_detail_screen.dart';

void main() {
  const testChain = ChainConfig(
    chainId: 1,
    name: 'Ethereum',
    symbol: 'ETH',
    rpcUrls: ['https://eth.llamarpc.com', 'https://rpc.ankr.com/eth'],
    explorerUrl: 'https://etherscan.io',
  );

  const customChain = ChainConfig(
    chainId: 99999,
    name: 'My Custom Chain',
    symbol: 'CUSTOM',
    rpcUrls: ['https://custom.rpc'],
    explorerUrl: 'https://custom.explorer',
  );

  Widget buildScreen({
    required ChainConfig chain,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: NetworkDetailScreen(
        chain: chain,
        isCustom: isCustom,
        onDelete: onDelete,
      ),
    );
  }

  group('NetworkDetailScreen', () {
    testWidgets('shows chain details', (tester) async {
      await tester.pumpWidget(buildScreen(chain: testChain));

      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('https://etherscan.io'), findsOneWidget);
    });

    testWidgets('shows RPC URLs', (tester) async {
      await tester.pumpWidget(buildScreen(chain: testChain));

      expect(find.text('https://eth.llamarpc.com'), findsOneWidget);
      expect(find.text('https://rpc.ankr.com/eth'), findsOneWidget);
    });

    testWidgets('shows delete button for custom chains', (tester) async {
      await tester.pumpWidget(buildScreen(
        chain: customChain,
        isCustom: true,
        onDelete: () {},
      ));

      expect(find.widgetWithText(FilledButton, 'Delete Network'), findsOneWidget);
    });

    testWidgets('hides delete button for built-in chains', (tester) async {
      await tester.pumpWidget(buildScreen(chain: testChain));

      expect(find.widgetWithText(FilledButton, 'Delete Network'), findsNothing);
    });
  });
}
