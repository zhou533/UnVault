import 'package:flutter/material.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/network/presentation/widgets/chain_list_tile.dart';

class ChainSelectorSheet extends StatefulWidget {
  const ChainSelectorSheet({super.key, required this.notifier});

  final NetworkNotifier notifier;

  @override
  State<ChainSelectorSheet> createState() => _ChainSelectorSheetState();
}

class _ChainSelectorSheetState extends State<ChainSelectorSheet> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chains = widget.notifier.availableChains;
    final activeChainId = widget.notifier.state.activeChain.chainId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Select Network',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: chains.length,
            itemBuilder: (context, index) {
              final chain = chains[index];
              return ChainListTile(
                chain: chain,
                isActive: chain.chainId == activeChainId,
                onTap: () {
                  widget.notifier.switchChain(chain.chainId);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showChainSelectorSheet({
  required BuildContext context,
  required NetworkNotifier notifier,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => ChainSelectorSheet(notifier: notifier),
  );
}
