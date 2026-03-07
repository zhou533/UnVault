import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddNetworkResult {
  const AddNetworkResult({
    required this.name,
    required this.rpcUrl,
    required this.chainId,
    required this.symbol,
    this.explorerUrl,
  });

  final String name;
  final String rpcUrl;
  final int chainId;
  final String symbol;
  final String? explorerUrl;
}

class AddNetworkScreen extends StatefulWidget {
  const AddNetworkScreen({
    super.key,
    required this.onSubmit,
  });

  final void Function(AddNetworkResult) onSubmit;

  @override
  State<AddNetworkScreen> createState() => _AddNetworkScreenState();
}

class _AddNetworkScreenState extends State<AddNetworkScreen> {
  final _nameController = TextEditingController();
  final _rpcController = TextEditingController();
  final _chainIdController = TextEditingController();
  final _symbolController = TextEditingController();
  final _explorerController = TextEditingController();

  bool get _isValid =>
      _nameController.text.isNotEmpty &&
      _rpcController.text.isNotEmpty &&
      _chainIdController.text.isNotEmpty &&
      _symbolController.text.isNotEmpty &&
      int.tryParse(_chainIdController.text) != null;

  bool get _isNonHttps =>
      _rpcController.text.isNotEmpty &&
      !_rpcController.text.startsWith('https://');

  @override
  void dispose() {
    _nameController.dispose();
    _rpcController.dispose();
    _chainIdController.dispose();
    _symbolController.dispose();
    _explorerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    widget.onSubmit(AddNetworkResult(
      name: _nameController.text,
      rpcUrl: _rpcController.text,
      chainId: int.parse(_chainIdController.text),
      symbol: _symbolController.text,
      explorerUrl: _explorerController.text.isEmpty
          ? null
          : _explorerController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Network')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Network Name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rpcController,
            decoration: const InputDecoration(labelText: 'RPC URL'),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          if (_isNonHttps)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Warning: This URL is not using HTTPS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _chainIdController,
            decoration: const InputDecoration(labelText: 'Chain ID'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _symbolController,
            decoration: const InputDecoration(labelText: 'Currency Symbol'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _explorerController,
            decoration: const InputDecoration(
              labelText: 'Block Explorer URL (optional)',
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isValid ? _submit : null,
            child: const Text('Add Network'),
          ),
        ],
      ),
    );
  }
}
