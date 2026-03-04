import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/network/application/network_notifier.dart';
import 'package:unvault/src/features/transfer/domain/send_form_state.dart';

part 'send_notifier.g.dart';

/// Manages the send-transaction form state, including gas estimation
/// and form validation.
@riverpod
class SendNotifier extends _$SendNotifier {
  @override
  SendFormState build() => const SendFormState();

  /// Updates the recipient address field.
  void setToAddress(String address) =>
      state = state.copyWith(toAddress: address, error: null);

  /// Updates the amount field.
  void setAmount(String amount) =>
      state = state.copyWith(amount: amount, error: null);

  /// Selects the gas speed tier.
  void setGasTier(GasTier tier) => state = state.copyWith(gasTier: tier);

  /// Fetches EIP-1559 base + priority fees from the active network.
  Future<void> estimateGas() async {
    state = state.copyWith(isEstimating: true, error: null);
    try {
      final rpc = ref.read(ethRpcServiceProvider);
      final network = ref.read(activeNetworkProvider);
      final fees = await rpc.getEip1559Fees(network.rpcUrls.first);

      // A simple ETH transfer always costs exactly 21 000 gas.
      const gasLimit = 21000;
      final gasEstimate = BigInt.from(gasLimit);

      state = state.copyWith(
        estimatedGasWei: gasEstimate,
        baseFee: fees.baseFee,
        priorityFee: fees.priorityFee,
        isEstimating: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isEstimating: false,
        error: 'Gas estimation failed: $e',
      );
    }
  }

  /// Calculates the total gas cost in wei for a given [tier].
  ///
  /// Formula: (baseFee + priorityFee * multiplier / 100) * gasLimit
  /// where multiplier is 90 % for slow, 100 % for standard, 120 % for fast.
  BigInt gasForTier(GasTier tier) {
    final base = state.baseFee ?? BigInt.zero;
    final priority = state.priorityFee ?? BigInt.zero;
    final gasLimit = state.estimatedGasWei ?? BigInt.from(21000);

    final multiplier = switch (tier) {
      GasTier.slow => BigInt.from(90),
      GasTier.standard => BigInt.from(100),
      GasTier.fast => BigInt.from(120),
    };

    // (baseFee + priority * multiplier / 100) * gasLimit
    final maxFee = base + priority * multiplier ~/ BigInt.from(100);
    return maxFee * gasLimit;
  }

  /// Validates the form. Returns an error message, or `null` if valid.
  String? validate() {
    if (state.toAddress.isEmpty) return 'Enter recipient address';
    if (!_isValidAddress(state.toAddress)) return 'Invalid address format';
    if (state.amount.isEmpty) return 'Enter amount';
    final parsed = double.tryParse(state.amount);
    if (parsed == null || parsed <= 0) return 'Invalid amount';
    if (state.baseFee == null) return 'Gas not estimated yet';
    return null;
  }

  bool _isValidAddress(String addr) {
    return addr.startsWith('0x') &&
        addr.length == 42 &&
        RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(addr);
  }
}
