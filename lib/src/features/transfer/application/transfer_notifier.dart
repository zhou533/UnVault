import 'package:flutter/foundation.dart';
import 'package:unvault/src/features/transfer/data/transfer_repository.dart';
import 'package:unvault/src/features/transfer/domain/transfer_result.dart';

enum TransferStatus { idle, broadcasting, success, failed }

class TransferState {
  const TransferState({
    this.status = TransferStatus.idle,
    this.result,
  });

  final TransferStatus status;
  final TransferResult? result;

  TransferState copyWith({
    TransferStatus? status,
    TransferResult? Function()? result,
  }) {
    return TransferState(
      status: status ?? this.status,
      result: result != null ? result() : this.result,
    );
  }
}

class TransferNotifier extends ChangeNotifier {
  TransferNotifier({required this.repository});

  final TransferRepository repository;
  TransferState _state = const TransferState();

  TransferState get state => _state;

  Future<void> submitTransaction({required String signedRawTx}) async {
    _state = _state.copyWith(status: TransferStatus.broadcasting);
    notifyListeners();

    final result = await repository.broadcastTransaction(signedRawTx);

    _state = _state.copyWith(
      status: result.isSuccess ? TransferStatus.success : TransferStatus.failed,
      result: () => result,
    );
    notifyListeners();
  }

  void reset() {
    _state = const TransferState();
    notifyListeners();
  }
}
