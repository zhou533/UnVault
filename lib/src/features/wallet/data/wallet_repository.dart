import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/accounts_dao.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/domain/account_model.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
import 'package:unvault/src/rust/api/wallet_api.dart' as rust_wallet;

class WalletRepository {
  const WalletRepository({
    required WalletsDao dao,
    required SecureStorageService storage,
    AccountsDao? accountsDao,
  })  : _dao = dao,
        _storage = storage,
        _accountsDao = accountsDao;

  final WalletsDao _dao;
  final SecureStorageService _storage;
  final AccountsDao? _accountsDao;

  static const maxWallets = 10;
  static const maxAccountsPerWallet = 20;

  Future<List<WalletModel>> getWallets() async {
    final rows = await _dao.getAllWallets();
    return rows
        .map((w) => WalletModel(
              id: w.id,
              name: w.name,
              firstAddress: '', // address stored in Accounts table
              isBackedUp: w.isBackedUp,
              createdAt: w.createdAt,
            ))
        .toList();
  }

  Future<WalletCreationResult> createWallet({
    required String name,
    required List<int> passwordBytes,
    int wordCount = 12,
  }) async {
    if (passwordBytes.length < 8) throw const PasswordTooShortException();
    await _enforceWalletLimit();

    final response = await rust_wallet.createWallet(
      password: passwordBytes,
      wordCount: wordCount,
    );

    final walletId = await _dao.insertWallet(
      WalletsCompanion.insert(name: name),
    );

    await _storage.storeWalletCredentials(
      walletId: walletId,
      encryptedMnemonic: response.encryptedMnemonic,
      salt: response.salt,
      argon2MemoryKib: response.argon2MemoryKib,
      argon2Iterations: response.argon2Iterations,
      argon2Parallelism: response.argon2Parallelism,
    );

    return WalletCreationResult(
      walletId: walletId,
      firstAddress: response.firstAddress,
      mnemonicBytes: Uint8List.fromList(response.mnemonicBytes),
    );
  }

  Future<WalletCreationResult> importWallet({
    required String name,
    required List<int> phraseBytes,
    required List<int> passwordBytes,
  }) async {
    if (passwordBytes.length < 8) throw const PasswordTooShortException();
    await _enforceWalletLimit();

    final response = await rust_wallet.importWallet(
      phraseBytes: phraseBytes,
      password: passwordBytes,
    );

    final walletId = await _dao.insertWallet(
      WalletsCompanion.insert(name: name),
    );

    await _storage.storeWalletCredentials(
      walletId: walletId,
      encryptedMnemonic: response.encryptedMnemonic,
      salt: response.salt,
      argon2MemoryKib: response.argon2MemoryKib,
      argon2Iterations: response.argon2Iterations,
      argon2Parallelism: response.argon2Parallelism,
    );

    return WalletCreationResult(
      walletId: walletId,
      firstAddress: response.firstAddress,
      mnemonicBytes: Uint8List(0),
    );
  }

  Future<void> markBackedUp(int walletId) async {
    await _dao.markBackedUp(walletId);
  }

  Future<int?> getActiveWalletId() => _storage.readActiveWalletId();

  Future<void> setActiveWalletId(int walletId) =>
      _storage.storeActiveWalletId(walletId);

  // --- Account management ---

  Future<List<AccountModel>> getAccountsForWallet(int walletId) async {
    final dao = _accountsDao;
    if (dao == null) return [];
    final rows = await dao.getAccountsForWallet(walletId);
    return rows
        .map((a) => AccountModel(
              id: a.id,
              walletId: a.walletId,
              derivationIndex: a.derivationIndex,
              address: a.address,
              name: a.name,
            ))
        .toList();
  }

  Future<int> addAccount({
    required int walletId,
    required String address,
    required int derivationIndex,
    String? name,
  }) async {
    final dao = _accountsDao!;
    final count = await dao.countAccountsForWallet(walletId);
    if (count >= maxAccountsPerWallet) throw const AccountLimitException();

    return dao.insertAccount(AccountsCompanion.insert(
      walletId: walletId,
      derivationIndex: derivationIndex,
      address: address,
      name: Value(name),
    ));
  }


  Future<void> deleteWallet({required int walletId}) async {
    final count = await _dao.countWallets();
    if (count <= 1) throw const LastWalletException();

    final dao = _accountsDao;
    if (dao != null) {
      await dao.deleteAccountsForWallet(walletId);
    }
    await _dao.deleteWallet(walletId);
    await _storage.deleteWalletCredentials(walletId: walletId);
  }

  Future<void> _enforceWalletLimit() async {
    final count = await _dao.countWallets();
    if (count >= maxWallets) throw const WalletLimitException();
  }
}

final class WalletCreationResult {
  const WalletCreationResult({
    required this.walletId,
    required this.firstAddress,
    required this.mnemonicBytes,
  });

  final int walletId;
  final String firstAddress;
  // MUST be zeroized by caller after backup display
  final Uint8List mnemonicBytes;
}
