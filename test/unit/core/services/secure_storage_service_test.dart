import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService sut;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    sut = SecureStorageService(storage: mockStorage);
  });

  group('storeWalletCredentials', () {
    test('writes all fields under namespaced keys', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await sut.storeWalletCredentials(
        walletId: 1,
        encryptedMnemonic: Uint8List.fromList([1, 2, 3]),
        salt: Uint8List.fromList([4, 5, 6]),
        argon2MemoryKib: 32768,
        argon2Iterations: 2,
        argon2Parallelism: 1,
      );

      verify(() => mockStorage.write(
        key: 'wallet_1_encrypted_mnemonic',
        value: any(named: 'value'),
      )).called(1);
    });
  });

  group('readWalletCredentials', () {
    test('returns null when wallet not found', () async {
      when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

      final result = await sut.readWalletCredentials(walletId: 999);

      expect(result, isNull);
    });
  });
}
