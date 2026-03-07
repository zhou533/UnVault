import 'package:flutter/material.dart';

class AddressInput extends StatelessWidget {
  const AddressInput({
    super.key,
    required this.onChanged,
    required this.errorText,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final String? errorText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Recipient Address',
        hintText: '0x...',
        errorText: errorText,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}
