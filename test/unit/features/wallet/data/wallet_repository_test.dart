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

  group('createWallet', () {
    test('throws PasswordTooShortException for password < 8 chars', () async {
      await expectLater(
        () => sut.createWallet(name: 'My Wallet', passwordBytes: [1, 2, 3]),
        throwsA(isA<PasswordTooShortException>()),
      );
    });
  });
}
