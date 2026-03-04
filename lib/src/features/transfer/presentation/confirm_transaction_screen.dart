import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';
import 'package:unvault/src/routing/route_names.dart';
import 'package:unvault/src/rust/api/transaction_api.dart' as rust_tx;
import 'package:unvault/src/rust/api/wallet_api.dart' as rust_wallet;

/// Confirm transaction screen.
///
/// Displays transaction details (amount, recipient, gas fee, total) and
/// handles the signing + broadcast flow when the user taps "Confirm & Send".
class ConfirmTransactionScreen extends ConsumerStatefulWidget {
  const ConfirmTransactionScreen({super.key});

  @override
  ConsumerState<ConfirmTransactionScreen> createState() =>
      _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState
    extends ConsumerState<ConfirmTransactionScreen> {
  bool _isSending = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra! as Map<String, dynamic>;
    final toAddress = extra['toAddress'] as String;
    final amount = extra['amount'] as String;
    final gasTier = extra['gasTier'] as String;
    final gasLimit = BigInt.parse(extra['gasLimit'] as String);
    final baseFee = BigInt.parse(extra['baseFee'] as String);
    final priorityFee = BigInt.parse(extra['priorityFee'] as String);
    final network = ref.watch(activeNetworkProvider);

    final multiplier = switch (gasTier) {
      'slow' => BigInt.from(90),
      'fast' => BigInt.from(120),
      _ => BigInt.from(100), // standard
    };
    final adjustedPriority = priorityFee * multiplier ~/ BigInt.from(100);
    final maxFeePerGas = baseFee + adjustedPriority;
    final gasCostWei = maxFeePerGas * gasLimit;

    final amountWei = _parseEtherToWei(amount, network.decimals);
    final totalWei = amountWei + gasCostWei;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Transaction')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Amount display
                Text(
                  '$amount ${network.symbol}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                // Detail card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'To',
                          value: _truncateAddress(toAddress),
                        ),
                        const Divider(),
                        _DetailRow(label: 'Network', value: network.name),
                        const Divider(),
                        _DetailRow(
                          label: 'Gas Fee',
                          value:
                              '${_formatWei(gasCostWei, network.decimals)} '
                              '${network.symbol}',
                        ),
                        const Divider(),
                        _DetailRow(
                          label: 'Total',
                          value:
                              '${_formatWei(totalWei, network.decimals)} '
                              '${network.symbol}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                // Confirm & Send button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSending
                        ? null
                        : () => _confirmAndSend(
                              toAddress: toAddress,
                              amountWei: amountWei,
                              gasLimit: gasLimit,
                              maxFeePerGas: maxFeePerGas,
                              maxPriorityFeePerGas: adjustedPriority,
                              amount: amount,
                              token: network.symbol,
                            ),
                    child: const Text('Confirm & Send'),
                  ),
                ),
              ],
            ),
          ),
          if (_isSending)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
        ],
      ),
    );
  }

  /// Prompts for password, decrypts mnemonic, signs tx, and broadcasts.
  Future<void> _confirmAndSend({
    required String toAddress,
    required BigInt amountWei,
    required BigInt gasLimit,
    required BigInt maxFeePerGas,
    required BigInt maxPriorityFeePerGas,
    required String amount,
    required String token,
  }) async {
    // 1. Prompt user for password
    final passwordBytes = await _promptPassword();
    if (passwordBytes == null) return; // User cancelled

    setState(() {
      _isSending = true;
      _error = null;
    });

    Uint8List? phraseBytes;
    try {
      final rpc = ref.read(ethRpcServiceProvider);
      final network = ref.read(activeNetworkProvider);
      final activeWallet = ref.read(activeWalletProvider);
      final db = ref.read(appDatabaseProvider);

      // 2. Look up account to get address and derivation index
      final account =
          await db.accountsDao.getAccount(activeWallet.accountId);
      if (account == null) throw Exception('No active account found');

      // 3. Get nonce
      final nonce = await rpc.getTransactionCount(
        network.rpcUrls.first,
        account.address,
      );

      // 4. Read wallet credentials from secure storage
      final storage = ref.read(secureStorageServiceProvider);
      final creds = await storage.readWalletCredentials(
        walletId: activeWallet.walletId,
      );
      if (creds == null) throw Exception('Wallet credentials not found');

      // 5. Decrypt mnemonic → phrase bytes (sensitive)
      phraseBytes = await rust_wallet.decryptMnemonic(
        password: passwordBytes,
        encryptedMnemonic: creds.encryptedMnemonic,
        salt: creds.salt,
        memoryKib: creds.argon2MemoryKib,
        iterations: creds.argon2Iterations,
        parallelism: creds.argon2Parallelism,
      );

      // 6. Sign using signTransactionWithSeed (private key stays in Rust)
      final signed = await rust_tx.signTransactionWithSeed(
        phraseBytes: phraseBytes,
        accountIndex: account.derivationIndex,
        chainId: BigInt.from(network.chainId),
        nonce: BigInt.from(nonce),
        to: toAddress,
        valueWei: amountWei.toString(),
        input: const [],
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
      );

      // 7. Zero the mnemonic bytes immediately
      phraseBytes.fillRange(0, phraseBytes.length, 0);
      phraseBytes = null;

      // 8. Broadcast the signed transaction
      final rawTxHex = '0x${_bytesToHex(signed.rawTx)}';
      final txHash = await rpc.sendRawTransaction(
        network.rpcUrls.first,
        rawTxHex,
      );

      if (!mounted) return;

      // 9. Navigate to result screen
      await context.pushNamed<void>(
        RouteNames.transactionResult,
        extra: <String, dynamic>{
          'txHash': txHash,
          'amount': amount,
          'token': token,
        },
      );
    } on Exception catch (e) {
      // Zero sensitive data on error path
      if (phraseBytes != null) {
        phraseBytes.fillRange(0, phraseBytes.length, 0);
      }
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = e.toString();
        });
      }
    } finally {
      // Zero password bytes
      passwordBytes.fillRange(0, passwordBytes.length, 0);
      if (mounted && _isSending) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Shows a dialog prompting the user for their wallet password.
  ///
  /// Returns password as `Uint8List` or `null` if the user cancels.
  /// SECURITY: The returned bytes must be zeroed by the caller after use.
  Future<Uint8List?> _promptPassword() async {
    final controller = TextEditingController();
    var obscure = true;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setDialogState(() => obscure = !obscure),
              ),
            ),
            onSubmitted: (value) {
              if (value.length >= 8) {
                Navigator.of(dialogContext).pop(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text;
                if (text.length >= 8) {
                  Navigator.of(dialogContext).pop(text);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (result == null || result.isEmpty) return null;

    // Convert to bytes immediately — the String will be GC'd.
    return Uint8List.fromList(result.codeUnits);
  }

  // ---------------------------------------------------------------------------
  // Helper functions
  // ---------------------------------------------------------------------------

  /// Parses a decimal ether string to wei [BigInt].
  static BigInt _parseEtherToWei(String ether, int decimals) {
    final parts = ether.split('.');
    final wholePart = parts[0];
    final fracPart = parts.length > 1
        ? parts[1].padRight(decimals, '0').substring(0, decimals)
        : ''.padRight(decimals, '0');
    return BigInt.parse('$wholePart$fracPart');
  }

  /// Formats a wei value to a human-readable ether string.
  static String _formatWei(BigInt wei, int decimals) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final whole = wei ~/ divisor;
    final remainder = wei.remainder(divisor).abs();
    final frac = remainder.toString().padLeft(decimals, '0').substring(0, 6);
    final trimmed = frac.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return '$whole';
    return '$whole.$trimmed';
  }

  /// Truncates an Ethereum address for display: 0x1234...5678
  static String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    final start = address.substring(0, 8);
    final end = address.substring(address.length - 6);
    return '$start...$end';
  }

  /// Converts bytes to a hex string (no 0x prefix).
  static String _bytesToHex(Uint8List bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

/// A row displaying a label and value in the transaction detail card.
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
