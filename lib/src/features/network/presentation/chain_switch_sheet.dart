import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';

/// Bottom sheet that lists all built-in mainnet chains and allows
/// the user to switch the active network.
class ChainSwitchSheet extends ConsumerWidget {
  const ChainSwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNetwork = ref.watch(activeNetworkProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select Network',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...BuiltInChains.all
              .where((c) => !c.isTestnet)
              .map((chain) => _ChainTile(
                    chain: chain,
                    isActive: chain.chainId == activeNetwork.chainId,
                    onTap: () {
                      ref
                          .read(activeNetworkProvider.notifier)
                          .switchNetwork(chain);
                      Navigator.of(context).pop();
                    },
                  )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Custom RPC'),
            onTap: () {
              Navigator.of(context).pop();
              // Navigate to network management (Task 14)
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile({
    required this.chain,
    required this.isActive,
    required this.onTap,
  });

  final ChainConfig chain;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        child: Text(
          chain.symbol.substring(0, chain.symbol.length.clamp(0, 3)),
          style: const TextStyle(fontSize: 10),
        ),
      ),
      title: Text(chain.name),
      trailing: isActive
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
