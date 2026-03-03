import 'dart:typed_data';

import 'package:unvault/src/core/database/app_database.dart';
import 'package:unvault/src/core/services/secure_storage_service.dart';
import 'package:unvault/src/rust/api/wallet_api.dart' as rust_wallet;

class AuthRepository {
  const AuthRepository({
    required AppDatabase db,
    required SecureStorageService storage,
  })  : _db = db,
        _storage = storage;

  final AppDatabase _db;
  final SecureStorageService _storage;

  Future<bool> isFirstLaunch() async {
    final count = await _db.walletCount();
    return count == 0;
  }

  /// Verifies a password by attempting mnemonic decryption for [walletId].
  /// Returns true if decryption succeeds (password is correct).
  Future<bool> verifyPassword({
    required int walletId,
    required List<int> passwordBytes,
  }) async {
    final creds = await _storage.readWalletCredentials(walletId: walletId);
    if (creds == null) return false;

    try {
      await rust_wallet.decryptMnemonic(
        password: Uint8List.fromList(passwordBytes),
        encryptedMnemonic: creds.encryptedMnemonic,
        salt: creds.salt,
        memoryKib: creds.argon2MemoryKib,
        iterations: creds.argon2Iterations,
        parallelism: creds.argon2Parallelism,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
