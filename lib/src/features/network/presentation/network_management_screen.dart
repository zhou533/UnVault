import 'package:flutter/material.dart';
import 'package:unvault/src/core/constants/chain_config.dart';

class NetworkManagementScreen extends StatelessWidget {
  const NetworkManagementScreen({
    super.key,
    required this.builtInChains,
    required this.customChains,
    required this.onDeleteCustomChain,
    required this.onAddNetwork,
  });

  final List<ChainConfig> builtInChains;
  final List<ChainConfig> customChains;
  final void Function(int chainId) onDeleteCustomChain;
  final VoidCallback onAddNetwork;

  @override
  Widget build(BuildContext context) {
    final mainnets = builtInChains.where((c) => !c.isTestnet).toList();
    final testnets = builtInChains.where((c) => c.isTestnet).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Network Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddNetwork,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          if (customChains.isNotEmpty) ...[
            _SectionHeader(title: 'Custom'),
            ...customChains.map((c) => _ChainTile(
                  chain: c,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onDeleteCustomChain(c.chainId),
                  ),
                )),
          ],
          _SectionHeader(title: 'Mainnet'),
          ...mainnets.map((c) => _ChainTile(chain: c)),
          _SectionHeader(title: 'Testnet'),
          ...testnets.map((c) => _ChainTile(chain: c)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _ChainTile extends StatelessWidget {
  const _ChainTile({required this.chain, this.trailing});
  final ChainConfig chain;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chain.name),
      subtitle: Text('${chain.symbol} · Chain ID: ${chain.chainId}'),
      trailing: trailing,
    );
  }
}
