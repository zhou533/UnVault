import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/data/wallet_repository.dart';

class MockWalletsDao extends Mock implements WalletsDao {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late WalletRepository sut;
  late MockWalletsDao mockDao;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockDao = MockWalletsDao();
    mockStorage = MockSecureStorageService();
    sut = WalletRepository(dao: mockDao, storage: mockStorage);
  });

  group('wallet limit', () {
    test('createWallet throws WalletLimitException when 10 wallets exist',
        () async {
      when(() => mockDao.countWallets()).thenAnswer((_) async => 10);

      await expectLater(
        () => sut.createWallet(
          name: 'New Wallet',
          passwordBytes: 'securepassword'.codeUnits,
        ),
        throwsA(isA<WalletLimitException>()),
      );
    });

    test('importWallet throws WalletLimitException when 10 wallets exist',
        () async {
      when(() => mockDao.countWallets()).thenAnswer((_) async => 10);

      await expectLater(
        () => sut.importWallet(
          name: 'Import Wallet',
          phraseBytes: 'test phrase'.codeUnits,
          passwordBytes: 'securepassword'.codeUnits,
        ),
        throwsA(isA<WalletLimitException>()),
      );
    });
  });

  group('active wallet', () {
    test('getActiveWalletId delegates to storage', () async {
      when(() => mockStorage.readActiveWalletId())
          .thenAnswer((_) async => 3);

      final result = await sut.getActiveWalletId();

      expect(result, 3);
    });

    test('getActiveWalletId returns null when none set', () async {
      when(() => mockStorage.readActiveWalletId())
          .thenAnswer((_) async => null);

      final result = await sut.getActiveWalletId();

      expect(result, isNull);
    });

    test('setActiveWalletId delegates to storage', () async {
      when(() => mockStorage.storeActiveWalletId(any()))
          .thenAnswer((_) async {});

      await sut.setActiveWalletId(5);

      verify(() => mockStorage.storeActiveWalletId(5)).called(1);
    });
  });
}
