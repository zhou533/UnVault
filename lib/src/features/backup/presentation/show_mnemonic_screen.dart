import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShowMnemonicScreen extends ConsumerWidget {
  const ShowMnemonicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Mnemonic')),
      body: const Center(child: Text('Show Mnemonic — TODO')),
    );
  }
}
