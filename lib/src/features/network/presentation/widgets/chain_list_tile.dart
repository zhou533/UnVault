import 'package:flutter/material.dart';
import 'package:unvault/src/core/constants/chain_config.dart';

class ChainListTile extends StatelessWidget {
  const ChainListTile({
    super.key,
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
        child: Text(chain.symbol[0]),
      ),
      title: Text(chain.name),
      subtitle: Row(
        children: [
          Text(chain.symbol),
          if (chain.isTestnet) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Testnet',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ],
      ),
      trailing: isActive ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}
