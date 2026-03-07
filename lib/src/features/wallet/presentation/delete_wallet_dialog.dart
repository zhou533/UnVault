import 'package:flutter/material.dart';

class DeleteWalletDialog extends StatefulWidget {
  const DeleteWalletDialog({
    super.key,
    required this.walletName,
    required this.onVerifyPassword,
    required this.onConfirmedDelete,
  });

  final String walletName;
  final Future<bool> Function(String password) onVerifyPassword;
  final VoidCallback onConfirmedDelete;

  @override
  State<DeleteWalletDialog> createState() => _DeleteWalletDialogState();
}

enum _Step { confirm, password, typeDelete }

class _DeleteWalletDialogState extends State<DeleteWalletDialog> {
  _Step _step = _Step.confirm;
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: switch (_step) {
        _Step.confirm => _buildConfirmStep(theme),
        _Step.password => _buildPasswordStep(theme),
        _Step.typeDelete => _buildTypeDeleteStep(theme),
      },
    );
  }

  Widget _buildConfirmStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delete "${widget.walletName}"?',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'This will permanently delete this wallet and all its accounts. '
          'Make sure you have backed up your recovery phrase.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                setState(() {
                  _step = _Step.password;
                  _controller.clear();
                  _error = null;
                });
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your password',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: _error,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _step = _Step.confirm;
                  _controller.clear();
                  _error = null;
                });
              },
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final ok =
                    await widget.onVerifyPassword(_controller.text);
                if (ok) {
                  setState(() {
                    _step = _Step.typeDelete;
                    _controller.clear();
                    _error = null;
                  });
                } else {
                  setState(() {
                    _error = 'Incorrect password';
                  });
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeDeleteStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type DELETE to confirm',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'This action cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Type DELETE',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _step = _Step.confirm;
                  _controller.clear();
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _controller.text == 'DELETE'
                  ? () => widget.onConfirmedDelete()
                  : null,
              child: const Text('Delete Wallet'),
            ),
          ],
        ),
      ],
    );
  }
}
