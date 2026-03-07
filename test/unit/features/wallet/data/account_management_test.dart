import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/daos/accounts_dao.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';
import 'package:unvault/src/features/wallet/domain/account_model.dart';

class MockWalletsDao extends Mock implements WalletsDao {}

class MockAccountsDao extends Mock implements AccountsDao {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('AccountModel', () {
    test('creates with required fields', () {
      final account = AccountModel(
        id: 1,
        walletId: 1,
        derivationIndex: 0,
        address: '0x1234567890abcdef1234567890abcdef12345678',
        name: 'Account 1',
      );

      expect(account.id, 1);
      expect(account.walletId, 1);
      expect(account.derivationIndex, 0);
      expect(account.address, '0x1234567890abcdef1234567890abcdef12345678');
      expect(account.name, 'Account 1');
    });

    test('name is optional', () {
      final account = AccountModel(
        id: 1,
        walletId: 1,
        derivationIndex: 0,
        address: '0x1234567890abcdef1234567890abcdef12345678',
      );

      expect(account.name, isNull);
    });
  });

  group('WalletRepository accounts', () {
    late WalletRepository sut;
    late MockWalletsDao mockWalletsDao;
    late MockAccountsDao mockAccountsDao;
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockWalletsDao = MockWalletsDao();
      mockAccountsDao = MockAccountsDao();
      mockStorage = MockSecureStorageService();
      sut = WalletRepository(
        dao: mockWalletsDao,
        accountsDao: mockAccountsDao,
        storage: mockStorage,
      );
    });

    test('getAccountsForWallet returns accounts from dao', () async {
      when(() => mockAccountsDao.getAccountsForWallet(1))
          .thenAnswer((_) async => []);

      final result = await sut.getAccountsForWallet(1);

      expect(result, isEmpty);
      verify(() => mockAccountsDao.getAccountsForWallet(1)).called(1);
    });

    test('throws AccountLimitException when 20 accounts exist', () async {
      when(() => mockAccountsDao.countAccountsForWallet(1))
          .thenAnswer((_) async => 20);

      await expectLater(
        () => sut.addAccount(walletId: 1, address: '0xaddr', derivationIndex: 20),
        throwsA(isA<AccountLimitException>()),
      );
    });
  });
}
