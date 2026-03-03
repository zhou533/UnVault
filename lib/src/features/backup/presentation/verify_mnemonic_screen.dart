import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/wallet/application/wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';

class VerifyMnemonicScreen extends ConsumerStatefulWidget {
  const VerifyMnemonicScreen({
    required this.walletId,
    required this.words,
    super.key,
  });

  final int walletId;
  final List<String> words;

  @override
  ConsumerState<VerifyMnemonicScreen> createState() =>
      _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends ConsumerState<VerifyMnemonicScreen> {
  late final List<int> _challengeIndices;
  late final List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    final rng = Random.secure();
    final indices = List.generate(widget.words.length, (i) => i)..shuffle(rng);
    _challengeIndices = indices.take(3).toList()..sort();
    _controllers = List.generate(3, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    for (var i = 0; i < _challengeIndices.length; i++) {
      if (_controllers[i].text.trim() != widget.words[_challengeIndices[i]]) {
        setState(() =>
            _error = 'Incorrect. Check word ${_challengeIndices[i] + 1}.');
        return;
      }
    }

    await ref.read(walletRepositoryProvider).markBackedUp(widget.walletId);
    ref.invalidate(walletListProvider);
    if (mounted) context.goNamed(RouteNames.walletList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Recovery Phrase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Enter the requested words to confirm your backup.'),
            const SizedBox(height: 24),
            ...List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Word #${_challengeIndices[i] + 1}',
                  ),
                ),
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _verify,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
