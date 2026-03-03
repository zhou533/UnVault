import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerifyMnemonicScreen extends ConsumerWidget {
  const VerifyMnemonicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Mnemonic')),
      body: const Center(child: Text('Verify Mnemonic — TODO')),
    );
  }
}
