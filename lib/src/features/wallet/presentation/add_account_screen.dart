import 'package:flutter/material.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({
    super.key,
    required this.walletName,
    required this.nextIndex,
    required this.onConfirm,
  });

  final String walletName;
  final int nextIndex;
  final void Function(String? name) onConfirm;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet: ${widget.walletName}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Derivation index: ${widget.nextIndex}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Path: m/44\'/60\'/0\'/0/${widget.nextIndex}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Account name (optional)',
                hintText: 'e.g. DeFi, Trading',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name =
                      _controller.text.trim().isEmpty ? null : _controller.text.trim();
                  widget.onConfirm(name);
                },
                child: const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
