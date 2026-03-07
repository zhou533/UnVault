import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unvault/src/features/auth/application/sensitive_action_guard.dart';

/// Shows a bottom sheet that requires password confirmation.
/// Returns true if password was verified, false/null if cancelled or failed.
Future<bool?> showPasswordConfirmSheet({
  required BuildContext context,
  required int walletId,
  required String actionDescription,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _PasswordConfirmSheet(
      walletId: walletId,
      actionDescription: actionDescription,
    ),
  );
}

class _PasswordConfirmSheet extends ConsumerStatefulWidget {
  const _PasswordConfirmSheet({
    required this.walletId,
    required this.actionDescription,
  });

  final int walletId;
  final String actionDescription;

  @override
  ConsumerState<_PasswordConfirmSheet> createState() =>
      _PasswordConfirmSheetState();
}

class _PasswordConfirmSheetState
    extends ConsumerState<_PasswordConfirmSheet> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final guard = ref.read(sensitiveActionGuardProvider);
    final passwordBytes = utf8.encode(_controller.text);

    final ok = await guard.verifyPassword(
      walletId: widget.walletId,
      passwordBytes: passwordBytes,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = 'Incorrect password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.actionDescription,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Enter your password to continue.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: _loading ? null : (_) => _confirm(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _confirm,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
