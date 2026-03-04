import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/transfer/application/send_notifier.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';
import 'package:unvault/src/routing/route_names.dart';

/// Send-transaction screen.
///
/// Collects recipient address, amount, and gas-tier selection before
/// navigating to the confirmation screen.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Kick off gas estimation as soon as the screen loads.
    Future.microtask(
      () => ref.read(sendProvider.notifier).estimateGas(),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sendState = ref.watch(sendProvider);
    final notifier = ref.read(sendProvider.notifier);
    final network = ref.watch(activeNetworkProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Send')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- To Address ---
              Text('To', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: '0x... or ENS name',
                  border: OutlineInputBorder(),
                ),
                onChanged: notifier.setToAddress,
              ),

              const SizedBox(height: 24),

              // --- Amount ---
              Text('Amount', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '0.0',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: notifier.setAmount,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TokenPill(symbol: network.symbol),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // MAX button -- placeholder, will integrate with
                      // actual balance in a future task.
                    },
                    child: const Text('MAX'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Gas Fee ---
              Text('Network Fee', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (sendState.isEstimating)
                const Center(child: CircularProgressIndicator.adaptive())
              else if (sendState.error != null)
                _GasError(
                  message: sendState.error!,
                  onRetry: notifier.estimateGas,
                )
              else
                _GasTierSelector(
                  selectedTier: sendState.gasTier,
                  gasForTier: notifier.gasForTier,
                  symbol: network.symbol,
                  decimals: network.decimals,
                  onTierSelected: notifier.setGasTier,
                ),

              const Spacer(),

              // --- Review button ---
              FilledButton(
                onPressed: _onReview,
                child: const Text('Review Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReview() {
    final notifier = ref.read(sendProvider.notifier);
    final validationError = notifier.validate();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final sendState = ref.read(sendProvider);
    context.pushNamed(
      RouteNames.confirmTransaction,
      extra: {
        'toAddress': sendState.toAddress,
        'amount': sendState.amount,
        'gasTier': sendState.gasTier.name,
        'gasLimit':
            (sendState.estimatedGasWei ?? BigInt.from(21000)).toString(),
        'baseFee': sendState.baseFee?.toString() ?? '0',
        'priorityFee': sendState.priorityFee?.toString() ?? '0',
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private helper widgets
// ---------------------------------------------------------------------------

/// Small pill that displays the active network's token symbol.
class _TokenPill extends StatelessWidget {
  const _TokenPill({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// Displays a gas-estimation error with a retry button.
class _GasError extends StatelessWidget {
  const _GasError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

/// Three-option gas speed selector (Slow / Standard / Fast).
class _GasTierSelector extends StatelessWidget {
  const _GasTierSelector({
    required this.selectedTier,
    required this.gasForTier,
    required this.symbol,
    required this.decimals,
    required this.onTierSelected,
  });

  final GasTier selectedTier;
  final BigInt Function(GasTier) gasForTier;
  final String symbol;
  final int decimals;
  final ValueChanged<GasTier> onTierSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: GasTier.values.map((tier) {
        final isSelected = tier == selectedTier;
        final cost = gasForTier(tier);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _GasTierCard(
              label: tier.label,
              cost: _formatGwei(cost),
              symbol: symbol,
              isSelected: isSelected,
              onTap: () => onTierSelected(tier),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Formats a wei value into a human-readable string with up to 6 decimal
  /// places of the native token.
  String _formatGwei(BigInt wei) {
    if (wei == BigInt.zero) return '0';
    final divisor = BigInt.from(10).pow(decimals);
    final whole = wei ~/ divisor;
    final remainder = wei.remainder(divisor).abs();
    final frac =
        remainder.toString().padLeft(decimals, '0').substring(0, 6);
    // Strip trailing zeros for readability.
    final trimmed = frac.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return '$whole';
    return '$whole.$trimmed';
  }
}

/// Individual gas tier card.
class _GasTierCard extends StatelessWidget {
  const _GasTierCard({
    required this.label,
    required this.cost,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String cost;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$cost $symbol',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Extension to provide user-facing labels for [GasTier].
// ---------------------------------------------------------------------------

extension _GasTierLabel on GasTier {
  String get label => switch (this) {
        GasTier.slow => 'Slow',
        GasTier.standard => 'Standard',
        GasTier.fast => 'Fast',
      };
}
