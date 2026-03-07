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

  setUp(() {
    dao = MockTransactionsDao();
    repo = HistoryRepository(dao: dao);
  });

  group('searchTransactions', () {
    test('searches by tx hash', () async {
      when(() => dao.searchByHash('0xabc'))
          .thenAnswer((_) async => [
            Transaction(
              hash: '0xabc123',
              fromAddress: '0xA',
              toAddress: '0xB',
              value: '100',
              chainId: 1,
              status: 'confirmed',
              timestamp: DateTime(2026, 1, 1),
            ),
          ]);

      final results = await repo.searchByHash('0xabc');

      expect(results, hasLength(1));
      expect(results.first.txHash, '0xabc123');
    });

    test('searches by address', () async {
      when(() => dao.searchByAddress('0xAddr', 1))
          .thenAnswer((_) async => [
            Transaction(
              hash: '0xdef',
              fromAddress: '0xAddr',
              toAddress: '0xOther',
              value: '200',
              chainId: 1,
              status: 'pending',
              timestamp: DateTime(2026, 1, 1),
            ),
          ]);

      final results = await repo.searchByAddress('0xAddr', 1);

      expect(results, hasLength(1));
      expect(results.first.from, '0xAddr');
    });
  });
}
