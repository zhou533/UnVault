import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class ImportWalletScreen extends ConsumerStatefulWidget {
  const ImportWalletScreen({required this.passwordBytes, super.key});

  final List<int> passwordBytes;

  @override
  ConsumerState<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends ConsumerState<ImportWalletScreen> {
  final _phraseController = TextEditingController();
  final _nameController = TextEditingController(text: 'Imported Wallet');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phraseController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final phrase = _phraseController.text.trim();
    if (phrase.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(walletRepositoryProvider);
      await repo.importWallet(
        name: _nameController.text,
        phraseBytes: phrase.codeUnits,
        passwordBytes: widget.passwordBytes,
      );
      ref.invalidate(walletListProvider);
      if (mounted) context.goNamed(RouteNames.walletList);
    } on Exception {
      setState(() => _error = 'Invalid mnemonic phrase');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Wallet Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phraseController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Recovery Phrase (12 or 24 words)',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _import,
              child: _loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Import Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
