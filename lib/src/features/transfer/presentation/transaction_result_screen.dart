import 'package:flutter/material.dart';

class TransactionResultScreen extends StatelessWidget {
  const TransactionResultScreen({
    super.key,
    required this.isSuccess,
    this.txHash,
    this.errorMessage,
    this.explorerUrl,
    required this.chainName,
    this.onDone,
    this.onRetry,
    this.onViewExplorer,
  });

  final bool isSuccess;
  final String? txHash;
  final String? errorMessage;
  final String? explorerUrl;
  final String chainName;
  final VoidCallback? onDone;
  final VoidCallback? onRetry;
  final VoidCallback? onViewExplorer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 80,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isSuccess ? 'Transaction Sent' : 'Transaction Failed',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              chainName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            if (isSuccess && txHash != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  txHash!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (!isSuccess && errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const Spacer(),
            if (isSuccess && explorerUrl != null)
              OutlinedButton(
                onPressed: onViewExplorer,
                child: const Text('View on Explorer'),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: isSuccess
                  ? FilledButton(
                      onPressed: onDone,
                      child: const Text('Done'),
                    )
                  : FilledButton(
                      onPressed: onRetry,
                      child: const Text('Try Again'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
