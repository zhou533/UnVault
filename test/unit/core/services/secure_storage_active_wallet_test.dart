import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SecureStorageService sut;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    sut = SecureStorageService(storage: mockStorage);
  });

  group('active wallet ID', () {
    test('storeActiveWalletId writes to correct key', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await sut.storeActiveWalletId(42);

      verify(() => mockStorage.write(key: 'active_wallet_id', value: '42'))
          .called(1);
    });

    test('readActiveWalletId returns stored ID', () async {
      when(() => mockStorage.read(key: 'active_wallet_id'))
          .thenAnswer((_) async => '7');

      final result = await sut.readActiveWalletId();

      expect(result, 7);
    });

    test('readActiveWalletId returns null when not set', () async {
      when(() => mockStorage.read(key: 'active_wallet_id'))
          .thenAnswer((_) async => null);

      final result = await sut.readActiveWalletId();

      expect(result, isNull);
    });
  });
}
