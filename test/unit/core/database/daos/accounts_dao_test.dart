import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/accounts_dao.dart';

void main() {
  late AppDatabase database;
  late AccountsDao dao;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = AccountsDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper to insert a wallet row and return its ID.
  Future<int> insertWallet(String name) async {
    return database.walletsDao.insertWallet(
      WalletsCompanion.insert(name: name),
    );
  }

  group('AccountsDao', () {
    group('insertAccount', () {
      test('stores account and returns its ID', () async {
        final walletId = await insertWallet('Test Wallet');

        final accountId = await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'a' * 40,
          ),
        );

        expect(accountId, isPositive);
      });
    });

    group('getAccountsForWallet', () {
      test('returns accounts for a specific wallet', () async {
        final walletId = await insertWallet('Wallet A');

        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'a' * 40,
          ),
        );
        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 1,
            address: '0x' + 'b' * 40,
          ),
        );

        final accounts = await dao.getAccountsForWallet(walletId);

        expect(accounts, hasLength(2));
        expect(accounts[0].derivationIndex, equals(0));
        expect(accounts[1].derivationIndex, equals(1));
      });

      test('does not return accounts from other wallets', () async {
        final walletA = await insertWallet('Wallet A');
        final walletB = await insertWallet('Wallet B');

        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletA,
            derivationIndex: 0,
            address: '0x' + 'a' * 40,
          ),
        );
        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletB,
            derivationIndex: 0,
            address: '0x' + 'b' * 40,
          ),
        );

        final accountsA = await dao.getAccountsForWallet(walletA);
        final accountsB = await dao.getAccountsForWallet(walletB);

        expect(accountsA, hasLength(1));
        expect(accountsA.first.address, equals('0x' + 'a' * 40));
        expect(accountsB, hasLength(1));
        expect(accountsB.first.address, equals('0x' + 'b' * 40));
      });

      test('returns empty list for wallet with no accounts', () async {
        final walletId = await insertWallet('Empty Wallet');

        final accounts = await dao.getAccountsForWallet(walletId);

        expect(accounts, isEmpty);
      });
    });

    group('getAccount', () {
      test('returns account by ID', () async {
        final walletId = await insertWallet('Test Wallet');
        final accountId = await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'c' * 40,
          ),
        );

        final account = await dao.getAccount(accountId);

        expect(account, isNotNull);
        expect(account!.id, equals(accountId));
        expect(account.walletId, equals(walletId));
        expect(account.derivationIndex, equals(0));
        expect(account.address, equals('0x' + 'c' * 40));
      });

      test('returns null for non-existent ID', () async {
        final account = await dao.getAccount(999);

        expect(account, isNull);
      });
    });

    group('countAccountsForWallet', () {
      test('returns correct count', () async {
        final walletId = await insertWallet('Test Wallet');

        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'a' * 40,
          ),
        );
        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 1,
            address: '0x' + 'b' * 40,
          ),
        );

        final count = await dao.countAccountsForWallet(walletId);

        expect(count, equals(2));
      });

      test('returns zero for wallet with no accounts', () async {
        final walletId = await insertWallet('Empty Wallet');

        final count = await dao.countAccountsForWallet(walletId);

        expect(count, equals(0));
      });

      test('does not count accounts from other wallets', () async {
        final walletA = await insertWallet('Wallet A');
        final walletB = await insertWallet('Wallet B');

        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletA,
            derivationIndex: 0,
            address: '0x' + 'a' * 40,
          ),
        );
        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletA,
            derivationIndex: 1,
            address: '0x' + 'b' * 40,
          ),
        );
        await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletB,
            derivationIndex: 0,
            address: '0x' + 'c' * 40,
          ),
        );

        final countA = await dao.countAccountsForWallet(walletA);
        final countB = await dao.countAccountsForWallet(walletB);

        expect(countA, equals(2));
        expect(countB, equals(1));
      });
    });

    group('account name', () {
      test('nullable name defaults to null', () async {
        final walletId = await insertWallet('Test Wallet');
        final accountId = await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'd' * 40,
          ),
        );

        final account = await dao.getAccount(accountId);

        expect(account, isNotNull);
        expect(account!.name, isNull);
      });

      test('stores optional name', () async {
        final walletId = await insertWallet('Test Wallet');
        final accountId = await dao.insertAccount(
          AccountsCompanion.insert(
            walletId: walletId,
            derivationIndex: 0,
            address: '0x' + 'e' * 40,
            name: const Value('My Account'),
          ),
        );

        final account = await dao.getAccount(accountId);

        expect(account, isNotNull);
        expect(account!.name, equals('My Account'));
      });
    });
  });
}
