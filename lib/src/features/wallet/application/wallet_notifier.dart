import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unvault/src/core/providers/app_providers.dart';
import 'package:unvault/src/features/auth/application/auth_notifier.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';

part 'wallet_notifier.g.dart';

@riverpod
Future<List<WalletModel>> walletList(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWallets();
}

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return WalletRepository(
    dao: db.walletsDao,
    accountsDao: db.accountsDao,
    storage: ref.watch(secureStorageServiceProvider),
  );
}

@riverpod
Future<int?> activeWalletId(Ref ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getActiveWalletId();
}
