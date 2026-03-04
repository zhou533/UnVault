import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
import 'package:unvault/src/routing/route_names.dart';

/// Screen listing all wallets and their accounts, allowing the user
/// to switch the active wallet/account.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletListProvider);
    final activeWallet = ref.watch(activeWalletProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No wallets yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.pushNamed(RouteNames.createWallet),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Wallet'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ...wallets.map(
                (wallet) => _WalletCard(
                  wallet: wallet,
                  activeWalletId: activeWallet.walletId,
                  activeAccountId: activeWallet.accountId,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.pushNamed(RouteNames.createWallet),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Wallet'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  const _WalletCard({
    required this.wallet,
    required this.activeWalletId,
    required this.activeAccountId,
  });

  final WalletModel wallet;
  final int activeWalletId;
  final int activeAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActiveWallet = wallet.id == activeWalletId;
    final accountsFuture = ref
        .watch(appDatabaseProvider)
        .accountsDao
        .getAccountsForWallet(wallet.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet header row
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wallet.name,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                ),
                if (isActiveWallet)
                  Chip(
                    label: const Text('Active'),
                    labelStyle:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const Divider(height: 16),
            // Accounts list
            FutureBuilder<List<Account>>(
              future: accountsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Error loading accounts: ${snapshot.error}');
                }
                final accounts = snapshot.data ?? [];
                if (accounts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('No accounts'),
                  );
                }
                return Column(
                  children: accounts.map((account) {
                    final isActive = isActiveWallet &&
                        account.id == activeAccountId;
                    return _AccountTile(
                      account: account,
                      isActive: isActive,
                      onTap: () {
                        ref
                            .read(activeWalletProvider.notifier)
                            .setWallet(wallet.id, account.id);
                        context.pop();
                      },
                    );
                  }).toList(),
                );
              },
            ),
            // Add account button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.onTap,
  });

  final Account account;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName =
        account.name ?? 'Account ${account.derivationIndex}';
    final truncatedAddress = _truncateAddress(account.address);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        radius: 16,
        child: Text(
          '${account.derivationIndex}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      title: Text(displayName),
      subtitle: Text(
        truncatedAddress,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontFamily: 'monospace'),
      ),
      trailing: isActive
          ? Chip(
              label: const Text('Active'),
              labelStyle:
                  Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : null,
      onTap: onTap,
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    final start = address.substring(0, 6);
    final end = address.substring(address.length - 4);
    return '$start...$end';
  }
}
