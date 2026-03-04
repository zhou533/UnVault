import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/database/daos/accounts_dao.dart';
import 'package:unvault/src/core/database/daos/wallets_dao.dart';
import 'package:unvault/src/core/exceptions/app_exceptions.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/features/wallet/domain/wallet_model.dart';
import 'package:unvault/src/rust/api/wallet_api.dart' as rust_wallet;

class WalletRepository {
  const WalletRepository({
    required WalletsDao dao,
    required AccountsDao accountsDao,
    required SecureStorageService storage,
  })  : _dao = dao,
        _accountsDao = accountsDao,
        _storage = storage;

  final WalletsDao _dao;
  final AccountsDao _accountsDao;
  final SecureStorageService _storage;

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

  /// Creates a new wallet: calls Rust to generate mnemonic + encrypt it,
  /// stores encrypted bytes in secure storage, saves wallet row in DB.
  ///
  /// Returns the new wallet's ID and the mnemonic bytes (zeroized by caller).
  Future<WalletCreationResult> createWallet({
    required String name,
    required List<int> passwordBytes,
    int wordCount = 12,
  }) async {
    if (passwordBytes.length < 8) throw const PasswordTooShortException();

    // 1. Call Rust FFI to create wallet
    final response = await rust_wallet.createWallet(
      password: passwordBytes,
      wordCount: wordCount,
    );

    // 2. Insert wallet row into DB
    final walletId = await _dao.insertWallet(
      WalletsCompanion.insert(name: name),
    );

    // 3. Insert first account (derivation index 0)
    await _accountsDao.insertAccount(
      AccountsCompanion.insert(
        walletId: walletId,
        derivationIndex: 0,
        address: response.firstAddress,
      ),
    );

    // 4. Store encrypted credentials in secure storage
    await _storage.storeWalletCredentials(
      walletId: walletId,
      encryptedMnemonic: response.encryptedMnemonic,
      salt: response.salt,
      argon2MemoryKib: response.argon2MemoryKib,
      argon2Iterations: response.argon2Iterations,
      argon2Parallelism: response.argon2Parallelism,
    );

    // 5. Return result including mnemonic bytes for backup display
    return WalletCreationResult(
      walletId: walletId,
      firstAddress: response.firstAddress,
      mnemonicBytes: Uint8List.fromList(response.mnemonicBytes),
    );
  }

  /// Imports a wallet from an existing mnemonic phrase.
  Future<WalletCreationResult> importWallet({
    required String name,
    required List<int> phraseBytes,
    required List<int> passwordBytes,
  }) async {
    if (passwordBytes.length < 8) throw const PasswordTooShortException();

    final response = await rust_wallet.importWallet(
      phraseBytes: phraseBytes,
      password: passwordBytes,
    );

    final walletId = await _dao.insertWallet(
      WalletsCompanion.insert(name: name),
    );

    await _accountsDao.insertAccount(
      AccountsCompanion.insert(
        walletId: walletId,
        derivationIndex: 0,
        address: response.firstAddress,
      ),
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
