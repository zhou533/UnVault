import 'package:flutter/material.dart';
import 'package:unvault/src/core/constants/chain_config.dart';

class NetworkDetailScreen extends StatelessWidget {
  const NetworkDetailScreen({
    super.key,
    required this.chain,
    this.isCustom = false,
    this.onDelete,
  });

  final ChainConfig chain;
  final bool isCustom;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chain.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailRow(label: 'Name', value: chain.name),
          _DetailRow(label: 'Symbol', value: chain.symbol),
          _DetailRow(label: 'Chain ID', value: '${chain.chainId}'),
          _DetailRow(label: 'Gas Type', value: chain.gasType.name),
          _DetailRow(label: 'Decimals', value: '${chain.decimals}'),
          if (chain.explorerUrl.isNotEmpty)
            _DetailRow(label: 'Explorer', value: chain.explorerUrl),
          const SizedBox(height: 16),
          Text(
            'RPC URLs',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...chain.rpcUrls.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(url),
              )),
          if (isCustom && onDelete != null) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDelete,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete Network'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
