import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({required this.passwordBytes, super.key});

  final List<int> passwordBytes;

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  final _nameController = TextEditingController(text: 'My Wallet');
  int _wordCount = 12;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final result = await repo.createWallet(
        name: _nameController.text,
        passwordBytes: widget.passwordBytes,
        wordCount: _wordCount,
      );
      ref.invalidate(walletListProvider);
      if (mounted) {
        context.goNamed(
          RouteNames.backupShow,
          extra: {
            'walletId': result.walletId,
            'mnemonicBytes': result.mnemonicBytes,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallet Name'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 12, label: Text('12 words')),
                ButtonSegment(value: 24, label: Text('24 words')),
              ],
              selected: {_wordCount},
              onSelectionChanged: (v) => setState(() => _wordCount = v.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _create,
              child: _loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Create Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
