import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/transactions_dao.dart';
import 'package:unvault/src/features/history/data/history_repository.dart';

/// Test address constants (42-char hex addresses).
const _addressA = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _addressB = '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _addressC = '0xcccccccccccccccccccccccccccccccccccccccc';
const _addressD = '0xdddddddddddddddddddddddddddddddddddddd';
const _addressUnknown = '0xffffffffffffffffffffffffffffffffffffffff';

void main() {
  late AppDatabase database;
  late TransactionsDao dao;
  late HistoryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dao = TransactionsDao(database);
    repository = HistoryRepository(transactionsDao: dao);
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper to insert a transaction via the repository.
  Future<void> insertTx({
    required String hash,
    String fromAddress = _addressA,
    String? toAddress = _addressB,
    String value = '1000000000000000000',
    int chainId = 1,
    String status = 'confirmed',
    DateTime? timestamp,
  }) async {
    await repository.saveTransaction(
      hash: hash,
      fromAddress: fromAddress,
      toAddress: toAddress,
      value: value,
      chainId: chainId,
      status: status,
      timestamp: timestamp ?? DateTime(2026, 3, 4, 12),
    );
  }

  group('HistoryRepository', () {
    group('insert and retrieve transactions', () {
      test('stores a transaction and retrieves it by sender address',
          () async {
        await insertTx(hash: '0xhash1');

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(1));
        expect(results.first.hash, equals('0xhash1'));
        expect(results.first.fromAddress, equals(_addressA));
        expect(results.first.toAddress, equals(_addressB));
        expect(results.first.value, equals('1000000000000000000'));
        expect(results.first.chainId, equals(1));
        expect(results.first.status, equals('confirmed'));
      });

      test('retrieves transaction by recipient address', () async {
        await insertTx(hash: '0xhash2');

        final results =
            await repository.getTransactionsForAddress(_addressB);

        expect(results, hasLength(1));
        expect(results.first.hash, equals('0xhash2'));
      });
    });

    group('filter by address', () {
      test('returns only transactions involving the given address', () async {
        await insertTx(hash: '0xhash_a');
        await insertTx(
          hash: '0xhash_c',
          fromAddress: _addressC,
          toAddress: _addressD,
        );

        final resultsA =
            await repository.getTransactionsForAddress(_addressA);
        final resultsC =
            await repository.getTransactionsForAddress(_addressC);
        final resultsB =
            await repository.getTransactionsForAddress(_addressB);

        expect(resultsA, hasLength(1));
        expect(resultsA.first.hash, equals('0xhash_a'));
        expect(resultsC, hasLength(1));
        expect(resultsC.first.hash, equals('0xhash_c'));
        // _addressB appears as toAddress in the first tx
        expect(resultsB, hasLength(1));
        expect(resultsB.first.hash, equals('0xhash_a'));
      });
    });

    group('ordering by timestamp descending', () {
      test('returns most recent transactions first', () async {
        await insertTx(
          hash: '0xold',
          timestamp: DateTime(2026, 3),
        );
        await insertTx(
          hash: '0xnew',
          timestamp: DateTime(2026, 3, 4),
        );
        await insertTx(
          hash: '0xmid',
          timestamp: DateTime(2026, 3, 2),
        );

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(3));
        expect(results[0].hash, equals('0xnew'));
        expect(results[1].hash, equals('0xmid'));
        expect(results[2].hash, equals('0xold'));
      });
    });

    group('upsert updates existing transaction', () {
      test('updates status when hash already exists', () async {
        await insertTx(hash: '0xhash_upsert', status: 'pending');

        // Upsert with updated status
        await insertTx(hash: '0xhash_upsert');

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(1));
        expect(results.first.status, equals('confirmed'));
      });

      test('updates value when hash already exists', () async {
        await insertTx(hash: '0xhash_val', value: '100');

        await insertTx(hash: '0xhash_val', value: '200');

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(1));
        expect(results.first.value, equals('200'));
      });
    });

    group('empty result for unknown address', () {
      test('returns empty list when no transactions match', () async {
        await insertTx(hash: '0xhash_known');

        final results =
            await repository.getTransactionsForAddress(_addressUnknown);

        expect(results, isEmpty);
      });
    });

    group('countForAddress', () {
      test('returns correct count for sender address', () async {
        await insertTx(hash: '0xhash_c1');
        await insertTx(hash: '0xhash_c2');

        final count = await repository.countForAddress(_addressA);

        expect(count, equals(2));
      });

      test('returns correct count for recipient address', () async {
        await insertTx(hash: '0xhash_c3');

        final count = await repository.countForAddress(_addressB);

        expect(count, equals(1));
      });

      test('returns zero for unknown address', () async {
        await insertTx(hash: '0xhash_c4');

        final count = await repository.countForAddress(_addressUnknown);

        expect(count, equals(0));
      });

      test('does not double-count when address is both sender and receiver',
          () async {
        await insertTx(
          hash: '0xhash_self',
          toAddress: _addressA,
        );

        final count = await repository.countForAddress(_addressA);

        // The SQL OR returns the row once, so count should be 1.
        expect(count, equals(1));
      });
    });

    group('multiple transactions with different statuses', () {
      test('stores and retrieves transactions with various statuses',
          () async {
        await insertTx(
          hash: '0xpending',
          status: 'pending',
          timestamp: DateTime(2026, 3, 4, 12),
        );
        await insertTx(
          hash: '0xconfirmed',
          timestamp: DateTime(2026, 3, 4, 11),
        );
        await insertTx(
          hash: '0xfailed',
          status: 'failed',
          timestamp: DateTime(2026, 3, 4, 10),
        );

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(3));
        expect(results[0].status, equals('pending'));
        expect(results[1].status, equals('confirmed'));
        expect(results[2].status, equals('failed'));
      });
    });

    group('nullable toAddress', () {
      test('stores transaction with null toAddress (contract creation)',
          () async {
        await insertTx(hash: '0xcontract', toAddress: null);

        final results =
            await repository.getTransactionsForAddress(_addressA);

        expect(results, hasLength(1));
        expect(results.first.toAddress, isNull);
      });
    });
  });
}
