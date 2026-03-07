import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';
import 'package:unvault/src/features/network/presentation/chain_selector_sheet.dart';
import 'package:unvault/src/features/network/presentation/widgets/connection_indicator.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

final networkNotifierProvider = ChangeNotifierProvider(
  (ref) => NetworkNotifier(NetworkRepository()),
);

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final networkNotifier = ref.watch(networkNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => showChainSelectorSheet(
            context: context,
            notifier: networkNotifier,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConnectionIndicator(status: networkNotifier.state.connectionStatus),
              const SizedBox(width: 8),
              Text(networkNotifier.state.activeChain.name),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.goNamed(RouteNames.createWallet),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) => wallets.isEmpty
            ? const Center(child: Text('No wallets. Tap + to create one.'))
            : ListView.builder(
                itemCount: wallets.length,
                itemBuilder: (ctx, i) {
                  final w = wallets[i];
                  return ListTile(
                    title: Text(w.name),
                    subtitle: Text(
                        w.firstAddress.isEmpty ? 'Loading...' : w.firstAddress),
                    trailing: w.isBackedUp
                        ? null
                        : const Icon(Icons.warning, color: Colors.orange),
                    onTap: () {/* navigate to wallet detail */},
                  );
                },
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
