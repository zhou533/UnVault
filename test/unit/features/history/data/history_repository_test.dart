import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/transactions_dao.dart';
import 'package:unvault/src/features/history/data/history_repository.dart';
import 'package:unvault/src/features/history/domain/transaction_record.dart';

class MockTransactionsDao extends Mock implements TransactionsDao {}

void main() {
  late MockTransactionsDao dao;
  late HistoryRepository repo;

  setUpAll(() {
    registerFallbackValue(TransactionsCompanion.insert(
      hash: '',
      fromAddress: '',
      value: '',
      chainId: 0,
      status: '',
      timestamp: DateTime(2026),
    ));
  });

  setUp(() {
    dao = MockTransactionsDao();
    repo = HistoryRepository(dao: dao);
  });

  group('HistoryRepository', () {
    test('getTransactions returns mapped records', () async {
      when(() => dao.getTransactions(
            chainId: 1,
            address: '0xAddr',
            limit: 20,
            offset: 0,
          )).thenAnswer((_) async => [
            Transaction(
              hash: '0xabc',
              fromAddress: '0xAddr',
              toAddress: '0xOther',
              value: '1000',
              chainId: 1,
              status: 'confirmed',
              timestamp: DateTime(2026, 1, 1),
            ),
          ]);

      final results = await repo.getTransactions(
        chainId: 1,
        address: '0xAddr',
        limit: 20,
        offset: 0,
      );

      expect(results, hasLength(1));
      expect(results.first.txHash, '0xabc');
      expect(results.first.status, TransactionStatus.confirmed);
      expect(results.first.value, BigInt.from(1000));
    });

    test('insertTransaction calls dao', () async {
      final record = TransactionRecord(
        txHash: '0xdef',
        from: '0xA',
        to: '0xB',
        value: BigInt.from(500),
        chainId: 1,
        status: TransactionStatus.pending,
        timestamp: DateTime(2026, 1, 1),
        nonce: 3,
      );

      when(() => dao.upsertTransaction(any()))
          .thenAnswer((_) async {});

      await repo.insertTransaction(record);

      verify(() => dao.upsertTransaction(any())).called(1);
    });

    test('updateStatus calls dao', () async {
      when(() => dao.updateStatus('0xabc', 'confirmed'))
          .thenAnswer((_) async {});

      await repo.updateStatus('0xabc', TransactionStatus.confirmed);

      verify(() => dao.updateStatus('0xabc', 'confirmed')).called(1);
    });
  });
}
