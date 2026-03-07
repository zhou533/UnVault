import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';
import 'package:unvault/src/features/network/domain/network_state.dart';
import 'package:unvault/src/features/network/presentation/chain_selector_sheet.dart';
import 'package:unvault/src/features/network/presentation/widgets/chain_list_tile.dart';
import 'package:unvault/src/features/network/presentation/widgets/connection_indicator.dart';

void main() {
  group('ConnectionIndicator', () {
    testWidgets('shows green for connected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConnectionIndicator(status: ConnectionStatus.connected)),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.green);
    });

    testWidgets('shows orange for degraded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConnectionIndicator(status: ConnectionStatus.degraded)),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.orange);
    });

    testWidgets('shows red for disconnected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConnectionIndicator(status: ConnectionStatus.disconnected)),
        ),
      );
      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
    });
  });

  group('ChainListTile', () {
    testWidgets('displays chain name and symbol', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainListTile(
              chain: BuiltInChains.ethereumMainnet,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
    });

    testWidgets('shows check icon when active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainListTile(
              chain: BuiltInChains.ethereumMainnet,
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('does not show check icon when inactive', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainListTile(
              chain: BuiltInChains.polygon,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainListTile(
              chain: BuiltInChains.polygon,
              isActive: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Polygon'));
      expect(tapped, isTrue);
    });

    testWidgets('shows testnet badge for testnet chains', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainListTile(
              chain: BuiltInChains.sepolia,
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Testnet'), findsOneWidget);
    });
  });

  group('ChainSelectorSheet', () {
    late NetworkNotifier notifier;

    setUp(() {
      notifier = NetworkNotifier(NetworkRepository());
    });

    testWidgets('displays all chains', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainSelectorSheet(notifier: notifier),
          ),
        ),
      );
      expect(find.text('Select Network'), findsOneWidget);
      for (final chain in BuiltInChains.all) {
        expect(find.text(chain.name), findsOneWidget);
      }
    });

    testWidgets('marks active chain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainSelectorSheet(notifier: notifier),
          ),
        ),
      );
      // Default is Ethereum
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('switching chain calls notifier', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainSelectorSheet(notifier: notifier),
          ),
        ),
      );
      await tester.tap(find.text('Polygon'));
      await tester.pumpAndSettle();
      expect(notifier.state.activeChain.chainId, 137);
    });
  });
}
