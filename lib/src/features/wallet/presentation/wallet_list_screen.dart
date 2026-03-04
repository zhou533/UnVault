import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/network/presentation/chain_switch_sheet.dart';
import 'package:unvault/src/features/wallet/application/balance_notifier.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/features/wallet/domain/balance_model.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
import 'package:unvault/src/routing/route_names.dart';

/// Main home screen showing wallet name, total balance, action buttons,
/// and the asset list per chain.
class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final activeNetwork = ref.watch(activeNetworkProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              walletsAsync: walletsAsync,
              activeNetwork: activeNetwork,
            ),
            Expanded(
              child: balancesAsync.when(
                data: (balances) => _HomeContent(balances: balances),
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.walletsAsync,
    required this.activeNetwork,
  });

  final AsyncValue<List<WalletModel>> walletsAsync;
  final ChainConfig activeNetwork;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Wallet name with dropdown arrow
          walletsAsync.when(
            data: (wallets) => GestureDetector(
              onTap: () => context.pushNamed(RouteNames.accounts),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    wallets.isEmpty ? 'No Wallet' : wallets.first.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text('Error'),
          ),
          const Spacer(),
          // Chain badge — opens chain switch bottom sheet
          ActionChip(
            label: Text(activeNetwork.symbol),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => const ChainSwitchSheet(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.balances});

  final List<TokenBalance> balances;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Total balance section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  _formatTotalBalance(balances),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Balance',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        // Action buttons: Send, Receive, Buy
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.arrow_upward,
                  label: 'Send',
                  onTap: () => context.pushNamed(RouteNames.send),
                ),
                _ActionButton(
                  icon: Icons.arrow_downward,
                  label: 'Receive',
                  onTap: () => context.pushNamed(RouteNames.receive),
                ),
                _ActionButton(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Buy',
                  onTap: () {}, // placeholder
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        // Asset list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final token = balances[index];
              return _AssetTile(token: token);
            },
            childCount: balances.length,
          ),
        ),
      ],
    );
  }

  String _formatTotalBalance(List<TokenBalance> tokens) {
    if (tokens.isEmpty) return '0';
    // Show first non-zero balance, or fall back to first
    for (final b in tokens) {
      if (b.balanceWei > BigInt.zero) {
        return _formatWei(b.balanceWei, b.decimals, b.symbol);
      }
    }
    return '0 ETH';
  }

  String _formatWei(BigInt wei, int decimals, String symbol) {
    final divisor = BigInt.from(10).pow(decimals);
    final whole = wei ~/ divisor;
    final remainder = wei.remainder(divisor);
    final frac = remainder.toString().padLeft(decimals, '0').substring(0, 4);
    return '$whole.$frac $symbol';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onTap,
          icon: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.token});

  final TokenBalance token;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          token.symbol.substring(0, token.symbol.length.clamp(0, 3)),
        ),
      ),
      title: Text(token.chainName),
      subtitle: Text(token.symbol),
      trailing: Text(
        _formatWei(token.balanceWei, token.decimals),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  String _formatWei(BigInt wei, int decimals) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final whole = wei ~/ divisor;
    final remainder = wei.remainder(divisor);
    final frac = remainder.toString().padLeft(decimals, '0').substring(0, 4);
    return '$whole.$frac';
  }
}
