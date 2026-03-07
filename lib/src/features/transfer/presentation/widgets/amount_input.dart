import 'package:flutter/material.dart';

class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.onChanged,
    required this.onMaxPressed,
    required this.errorText,
    required this.balance,
    required this.symbol,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onMaxPressed;
  final String? errorText;
  final String balance;
  final String symbol;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Balance: $balance $symbol',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            GestureDetector(
              onTap: onMaxPressed,
              child: Text(
                'MAX',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: '0.0',
            errorText: errorText,
            border: const OutlineInputBorder(),
            suffixText: symbol,
          ),
        ),
      ],
    );
  }
}
