import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfirmTransactionScreen extends ConsumerWidget {
  const ConfirmTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Transaction')),
      body: const Center(child: Text('Confirm Transaction — TODO')),
    );
  }
}
