import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unvault/src/features/network/presentation/widgets/connection_indicator.dart';
import 'package:unvault/src/features/transfer/application/send_notifier.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/address_input.dart';
import 'package:unvault/src/features/transfer/presentation/widgets/amount_input.dart';
import 'package:unvault/src/features/wallet/presentation/wallet_list_screen.dart';
import 'package:unvault/src/routing/route_names.dart';

final sendNotifierProvider = ChangeNotifierProvider(
  (ref) => SendNotifier(),
);

class SendScreen extends ConsumerWidget {
  const SendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sendState = ref.watch(sendNotifierProvider).state;
    final sendNotifier = ref.read(sendNotifierProvider);
    final networkState = ref.watch(networkNotifierProvider).state;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConnectionIndicator(status: networkState.connectionStatus),
            const SizedBox(width: 8),
            Text('Send ${networkState.activeChain.symbol}'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AddressInput(
              onChanged: sendNotifier.setAddress,
              errorText: sendState.addressError,
            ),
            const SizedBox(height: 16),
            AmountInput(
              onChanged: sendNotifier.setAmount,
              onMaxPressed: () => sendNotifier.setMaxAmount('0'),
              errorText: sendState.amountError,
              balance: '0.0',
              symbol: networkState.activeChain.symbol,
            ),
            const SizedBox(height: 24),
            const Spacer(),
            FilledButton(
              onPressed: sendState.isValid
                  ? () => context.pushNamed(RouteNames.confirmTransaction)
                  : null,
              child: const Text('Review Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
