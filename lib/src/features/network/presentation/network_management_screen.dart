import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/network/data/network_repository.dart';

/// Provides a [NetworkRepository] backed by the app database.
final networkRepositoryProvider = Provider<NetworkRepository>((ref) {
  return NetworkRepository(ref.watch(appDatabaseProvider).networksDao);
});

/// Provides the list of all networks, seeding built-in chains if needed.
final allNetworksProvider =
    FutureProvider.autoDispose<List<Network>>((ref) async {
  final repo = ref.watch(networkRepositoryProvider);
  await repo.seedBuiltInChains();
  return repo.getAllNetworks();
});

/// Full-page network management screen.
class NetworkManagementScreen extends ConsumerWidget {
  const NetworkManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networksAsync = ref.watch(allNetworksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Network Management')),
      body: networksAsync.when(
        data: (networks) {
          if (networks.isEmpty) {
            return const Center(child: Text('No networks configured'));
          }

          final builtIn =
              networks.where((n) => !n.isCustom).toList();
          final custom =
              networks.where((n) => n.isCustom).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (builtIn.isNotEmpty) ...[
                const _SectionHeader(title: 'BUILT-IN NETWORKS'),
                ...builtIn.map(
                  (network) => _NetworkTile(
                    network: network,
                    canDelete: false,
                  ),
                ),
              ],
              if (custom.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SectionHeader(title: 'CUSTOM NETWORKS'),
                ...custom.map(
                  (network) => _NetworkTile(
                    network: network,
                    canDelete: true,
                    onDelete: () =>
                        _deleteNetwork(context, ref, network),
                  ),
                ),
              ],
              const SizedBox(height: 80), // space for FAB
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNetworkDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Custom RPC'),
      ),
    );
  }

  Future<void> _deleteNetwork(
    BuildContext context,
    WidgetRef ref,
    Network network,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Network'),
        content: Text('Remove "${network.name}" from your networks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      await ref
          .read(appDatabaseProvider)
          .networksDao
          .deleteNetwork(network.chainId);
      ref.invalidate(allNetworksProvider);
    }
  }

  Future<void> _showAddNetworkDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<NetworksCompanion?>(
      context: context,
      builder: (context) => const _AddNetworkDialog(),
    );

    if (result != null) {
      await ref
          .read(appDatabaseProvider)
          .networksDao
          .upsertNetwork(result);
      ref.invalidate(allNetworksProvider);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({
    required this.network,
    required this.canDelete,
    this.onDelete,
  });

  final Network network;
  final bool canDelete;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            network.symbol.substring(
              0,
              network.symbol.length.clamp(0, 3),
            ),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(network.name)),
            if (network.isTestnet)
              Chip(
                label: const Text('Testnet'),
                labelStyle:
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                backgroundColor:
                    Theme.of(context).colorScheme.tertiaryContainer,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Text(
          network.rpcUrl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: canDelete
            ? IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }
}

class _AddNetworkDialog extends StatefulWidget {
  const _AddNetworkDialog();

  @override
  State<_AddNetworkDialog> createState() => _AddNetworkDialogState();
}

class _AddNetworkDialogState extends State<_AddNetworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _chainIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _rpcUrlController = TextEditingController();
  final _explorerUrlController = TextEditingController();

  @override
  void dispose() {
    _chainIdController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _rpcUrlController.dispose();
    _explorerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Network'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _chainIdController,
                decoration: const InputDecoration(
                  labelText: 'Chain ID',
                  hintText: 'e.g., 42161',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Chain ID is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Must be a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Network Name',
                  hintText: 'e.g., Arbitrum One',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'e.g., ETH',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Symbol is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rpcUrlController,
                decoration: const InputDecoration(
                  labelText: 'RPC URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'RPC URL is required';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'Must be a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explorerUrlController,
                decoration: const InputDecoration(
                  labelText: 'Explorer URL (optional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _onSubmit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final companion = NetworksCompanion(
      chainId: Value(int.parse(_chainIdController.text)),
      name: Value(_nameController.text.trim()),
      symbol: Value(_symbolController.text.trim()),
      rpcUrl: Value(_rpcUrlController.text.trim()),
      explorerUrl: Value(
        _explorerUrlController.text.trim().isEmpty
            ? ''
            : _explorerUrlController.text.trim(),
      ),
      isCustom: const Value(true),
    );

    Navigator.pop(context, companion);
  }
}
