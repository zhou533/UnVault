import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/auth/data/auth_repository.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late AuthRepository sut;
  late MockSecureStorageService mockStorage;
  late MockAppDatabase mockDb;

  setUp(() {
    mockStorage = MockSecureStorageService();
    mockDb = MockAppDatabase();
    sut = AuthRepository(storage: mockStorage, db: mockDb);
  });

  group('isFirstLaunch', () {
    test('returns true when no wallets in DB', () async {
      when(() => mockDb.walletCount()).thenAnswer((_) async => 0);
      expect(await sut.isFirstLaunch(), isTrue);
    });

    test('returns false when wallets exist', () async {
      when(() => mockDb.walletCount()).thenAnswer((_) async => 1);
      expect(await sut.isFirstLaunch(), isFalse);
    });
  });
}
