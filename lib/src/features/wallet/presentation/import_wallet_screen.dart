import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportWalletScreen extends ConsumerWidget {
  const ImportWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: const Center(child: Text('Import Wallet — TODO')),
    );
  }
}
