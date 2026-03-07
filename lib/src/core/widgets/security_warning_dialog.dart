import 'package:flutter/material.dart';

/// Shows a security warning dialog for rooted/jailbroken devices.
/// Returns `true` if user checked "don't show again", `false` otherwise.
Future<bool?> showSecurityWarningDialog({
  required BuildContext context,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _SecurityWarningDialog(),
  );
}

class _SecurityWarningDialog extends StatefulWidget {
  const _SecurityWarningDialog();

  @override
  State<_SecurityWarningDialog> createState() => _SecurityWarningDialogState();
}

class _SecurityWarningDialogState extends State<_SecurityWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Security Warning'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This device appears to be rooted or jailbroken. '
            'This may compromise the security of your wallet '
            'and private keys.',
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
            child: Row(
              children: [
                Checkbox(
                  value: _dontShowAgain,
                  onChanged: (v) =>
                      setState(() => _dontShowAgain = v ?? false),
                ),
                const Text("Don't show again"),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_dontShowAgain),
          child: const Text('I Understand'),
        ),
      ],
    );
  }
}
