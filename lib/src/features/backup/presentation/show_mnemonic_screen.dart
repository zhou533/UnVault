import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/widgets/screen_security_wrapper.dart';
import 'package:unvault/src/routing/route_names.dart';

class ShowMnemonicScreen extends StatelessWidget {
  const ShowMnemonicScreen({
    required this.walletId,
    required this.mnemonicBytes,
    super.key,
  });

  final int walletId;
  final Uint8List mnemonicBytes;

  @override
  Widget build(BuildContext context) {
    // SECURITY: Convert bytes to words only for display, never store as String
    final phrase = String.fromCharCodes(mnemonicBytes);
    final words = phrase.split(' ');

    return ScreenSecurityWrapper(child: Scaffold(
      appBar: AppBar(title: const Text('Backup Recovery Phrase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Write down these words in order and store them safely. '
              'They are the only way to recover your wallet.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: words.length,
                itemBuilder: (ctx, i) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          words[i],
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.goNamed(
                  RouteNames.backupVerify,
                  extra: {
                    'walletId': walletId,
                    'words': words,
                  },
                );
              },
              child: const Text("I've written it down"),
            ),
          ],
        ),
      ),
    ));
  }
}
