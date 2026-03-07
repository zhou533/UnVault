import 'package:flutter/material.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';

class WalletDrawer extends StatelessWidget {
  const WalletDrawer({
    super.key,
    required this.wallets,
    required this.activeWalletId,
    required this.onWalletSelected,
    required this.onAddWallet,
  });

  final List<WalletModel> wallets;
  final int activeWalletId;
  final void Function(int walletId) onWalletSelected;
  final VoidCallback onAddWallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Wallets',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                '(${wallets.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isActive = wallet.id == activeWalletId;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(wallet.name[0].toUpperCase()),
                ),
                title: Text(wallet.name),
                subtitle: Text(
                  wallet.firstAddress.isEmpty
                      ? 'Loading...'
                      : wallet.firstAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isActive
                    ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                    : !wallet.isBackedUp
                        ? const Icon(Icons.warning, color: Colors.orange)
                        : null,
                onTap: () => onWalletSelected(wallet.id),
              );
            },
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Wallet'),
          onTap: onAddWallet,
        ),
      ],
    );
  }
}
