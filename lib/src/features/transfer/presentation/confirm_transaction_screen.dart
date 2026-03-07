import 'package:flutter/material.dart';

class ConfirmTransactionScreen extends StatelessWidget {
  const ConfirmTransactionScreen({
    super.key,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.symbol,
    required this.gasCost,
    required this.chainName,
    this.onConfirm,
  });

  final String fromAddress;
  final String toAddress;
  final String amount;
  final String symbol;
  final String gasCost;
  final String chainName;
  final VoidCallback? onConfirm;

  String _computeTotal() {
    final amountVal = double.tryParse(amount) ?? 0;
    final gasVal = double.tryParse(gasCost) ?? 0;
    final total = amountVal + gasVal;
    return '${total.toStringAsFixed(6)} $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              children: [
                _DetailRow(label: 'Network', value: chainName),
                const Divider(height: 24),
                _DetailRow(label: 'From', value: fromAddress, mono: true),
                const SizedBox(height: 8),
                _DetailRow(label: 'To', value: toAddress, mono: true),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                _DetailRow(label: 'Amount', value: '$amount $symbol'),
                const SizedBox(height: 8),
                _DetailRow(label: 'Gas Fee', value: '$gasCost $symbol'),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Total',
                  value: _computeTotal(),
                  bold: true,
                ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: onConfirm,
              child: const Text('Confirm & Send'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: mono ? 'monospace' : null,
            fontSize: mono ? 13 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
