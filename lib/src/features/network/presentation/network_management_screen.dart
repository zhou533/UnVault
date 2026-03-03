import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkManagementScreen extends ConsumerWidget {
  const NetworkManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network Management')),
      body: const Center(child: Text('Network Management — TODO')),
    );
  }
}
