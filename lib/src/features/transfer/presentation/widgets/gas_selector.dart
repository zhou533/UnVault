import 'package:flutter/material.dart';
import 'package:unvault/src/features/transfer/domain/gas_estimate.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';

class GasSelector extends StatelessWidget {
  const GasSelector({
    super.key,
    required this.estimate,
    required this.selectedTier,
    required this.onTierChanged,
  });

  final GasEstimate estimate;
  final GasTierSelection selectedTier;
  final ValueChanged<GasTierSelection> onTierChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GasTierCard(
          tier: estimate.slow,
          selection: GasTierSelection.slow,
          isSelected: selectedTier == GasTierSelection.slow,
          onTap: () => onTierChanged(GasTierSelection.slow),
        ),
        const SizedBox(width: 8),
        _GasTierCard(
          tier: estimate.standard,
          selection: GasTierSelection.standard,
          isSelected: selectedTier == GasTierSelection.standard,
          onTap: () => onTierChanged(GasTierSelection.standard),
        ),
        const SizedBox(width: 8),
        _GasTierCard(
          tier: estimate.fast,
          selection: GasTierSelection.fast,
          isSelected: selectedTier == GasTierSelection.fast,
          onTap: () => onTierChanged(GasTierSelection.fast),
        ),
      ],
    );
  }
}

class _GasTierCard extends StatelessWidget {
  const _GasTierCard({
    required this.tier,
    required this.selection,
    required this.isSelected,
    required this.onTap,
  });

  final GasTier tier;
  final GasTierSelection selection;
  final bool isSelected;
  final VoidCallback onTap;

  String _formatCost(BigInt wei) {
    final ethValue = wei / BigInt.from(10).pow(18);
    return ethValue.toStringAsFixed(6);
  }

  String _formatTime(Duration d) {
    if (d.inMinutes > 0) return '~${d.inMinutes}m';
    return '~${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCost(tier.totalCostWei),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                _formatTime(tier.estimatedTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
