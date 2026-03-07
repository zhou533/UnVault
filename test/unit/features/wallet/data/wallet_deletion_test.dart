import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/daos/accounts_dao.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';

class MockWalletsDao extends Mock implements WalletsDao {}

class MockAccountsDao extends Mock implements AccountsDao {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockWalletsDao walletsDao;
  late MockAccountsDao accountsDao;
  late MockSecureStorageService storage;
  late WalletRepository repo;

  setUp(() {
    walletsDao = MockWalletsDao();
    accountsDao = MockAccountsDao();
    storage = MockSecureStorageService();
    repo = WalletRepository(
      dao: walletsDao,
      storage: storage,
      accountsDao: accountsDao,
    );
  });

  group('deleteWallet', () {
    test('throws LastWalletException when only one wallet exists', () async {
      when(() => walletsDao.countWallets()).thenAnswer((_) async => 1);

      expect(
        () => repo.deleteWallet(walletId: 1),
        throwsA(isA<LastWalletException>()),
      );
    });

    test('deletes accounts, wallet row, and secure storage', () async {
      when(() => walletsDao.countWallets()).thenAnswer((_) async => 2);
      when(() => accountsDao.deleteAccountsForWallet(1))
          .thenAnswer((_) async {});
      when(() => walletsDao.deleteWallet(1)).thenAnswer((_) async {});
      when(() => storage.deleteWalletCredentials(walletId: 1))
          .thenAnswer((_) async {});

      await repo.deleteWallet(walletId: 1);

      verify(() => accountsDao.deleteAccountsForWallet(1)).called(1);
      verify(() => walletsDao.deleteWallet(1)).called(1);
      verify(() => storage.deleteWalletCredentials(walletId: 1)).called(1);
    });

    test('works when accountsDao is null (skips account deletion)', () async {
      final repoNoAccounts = WalletRepository(
        dao: walletsDao,
        storage: storage,
      );
      when(() => walletsDao.countWallets()).thenAnswer((_) async => 2);
      when(() => walletsDao.deleteWallet(1)).thenAnswer((_) async {});
      when(() => storage.deleteWalletCredentials(walletId: 1))
          .thenAnswer((_) async {});

      await repoNoAccounts.deleteWallet(walletId: 1);

      verify(() => walletsDao.deleteWallet(1)).called(1);
      verify(() => storage.deleteWalletCredentials(walletId: 1)).called(1);
      verifyNever(() => accountsDao.deleteAccountsForWallet(any()));
    });
  });
}
