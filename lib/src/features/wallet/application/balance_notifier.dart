import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/constants/chain_config.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/wallet/application/active_wallet_notifier.dart';
import 'package:unvault/src/features/wallet/domain/balance_model.dart';

part 'balance_notifier.g.dart';

/// Fetches native token balances for the active account across all
/// built-in mainnet chains.
@riverpod
Future<List<TokenBalance>> accountBalances(Ref ref) async {
  final activeWallet = ref.watch(activeWalletProvider);
  if (activeWallet.accountId == 0) return [];

  final rpc = ref.watch(ethRpcServiceProvider);
  final db = ref.watch(appDatabaseProvider);

  // Get account address from DB
  final account = await db.accountsDao.getAccount(activeWallet.accountId);
  if (account == null) return [];

  final balances = <TokenBalance>[];

  // Fetch balance for each built-in chain
  for (final chain in BuiltInChains.all) {
    if (chain.isTestnet) continue; // skip testnets in default view
    try {
      final balance =
          await rpc.getBalance(chain.rpcUrls.first, account.address);
      balances.add(
        TokenBalance(
          symbol: chain.symbol,
          chainName: chain.name,
          chainId: chain.chainId,
          balanceWei: balance,
          decimals: chain.decimals,
        ),
      );
    } on Exception catch (_) {
      // RPC failure for one chain shouldn't block others
      balances.add(
        TokenBalance(
          symbol: chain.symbol,
          chainName: chain.name,
          chainId: chain.chainId,
          balanceWei: BigInt.zero,
          decimals: chain.decimals,
        ),
      );
    }
  }

  return balances;
}
