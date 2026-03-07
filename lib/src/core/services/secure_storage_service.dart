import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive wallet data in the platform secure keychain/keystore.
/// Keys are namespaced by wallet ID to support multiple wallets.
/// All binary data is base64-encoded for storage.
class SecureStorageService {
  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Stores the full encryption envelope for a wallet.
  Future<void> storeWalletCredentials({
    required int walletId,
    required Uint8List encryptedMnemonic,
    required Uint8List salt,
    required int argon2MemoryKib,
    required int argon2Iterations,
    required int argon2Parallelism,
  }) async {
    final prefix = 'wallet_$walletId';
    await Future.wait([
      _storage.write(
        key: '${prefix}_encrypted_mnemonic',
        value: base64.encode(encryptedMnemonic),
      ),
      _storage.write(
        key: '${prefix}_salt',
        value: base64.encode(salt),
      ),
      _storage.write(
        key: '${prefix}_argon2_memory',
        value: argon2MemoryKib.toString(),
      ),
      _storage.write(
        key: '${prefix}_argon2_iterations',
        value: argon2Iterations.toString(),
      ),
      _storage.write(
        key: '${prefix}_argon2_parallelism',
        value: argon2Parallelism.toString(),
      ),
    ]);
  }

  /// Reads the wallet credentials, returns null if not found.
  Future<WalletCredentials?> readWalletCredentials({
    required int walletId,
  }) async {
    final prefix = 'wallet_$walletId';
    final encMnemonic =
        await _storage.read(key: '${prefix}_encrypted_mnemonic');
    if (encMnemonic == null) return null;

    final salt = await _storage.read(key: '${prefix}_salt');
    final memory = await _storage.read(key: '${prefix}_argon2_memory');
    final iterations =
        await _storage.read(key: '${prefix}_argon2_iterations');
    final parallelism =
        await _storage.read(key: '${prefix}_argon2_parallelism');

    if (salt == null ||
        memory == null ||
        iterations == null ||
        parallelism == null) {
      return null;
    }

    return WalletCredentials(
      encryptedMnemonic: base64.decode(encMnemonic),
      salt: base64.decode(salt),
      argon2MemoryKib: int.parse(memory),
      argon2Iterations: int.parse(iterations),
      argon2Parallelism: int.parse(parallelism),
    );
  }

  /// Stores the active wallet ID.
  Future<void> storeActiveWalletId(int walletId) async {
    await _storage.write(
      key: 'active_wallet_id',
      value: walletId.toString(),
    );
  }

  /// Reads the active wallet ID, or null if none set.
  Future<int?> readActiveWalletId() async {
    final value = await _storage.read(key: 'active_wallet_id');
    return value != null ? int.parse(value) : null;
  }

  /// Deletes all credentials for a wallet. Called on wallet removal.
  Future<void> deleteWalletCredentials({required int walletId}) async {
    final prefix = 'wallet_$walletId';
    await Future.wait([
      _storage.delete(key: '${prefix}_encrypted_mnemonic'),
      _storage.delete(key: '${prefix}_salt'),
      _storage.delete(key: '${prefix}_argon2_memory'),
      _storage.delete(key: '${prefix}_argon2_iterations'),
      _storage.delete(key: '${prefix}_argon2_parallelism'),
    ]);
  }
}

/// Decrypted credentials read from secure storage.
final class WalletCredentials {
  const WalletCredentials({
    required this.encryptedMnemonic,
    required this.salt,
    required this.argon2MemoryKib,
    required this.argon2Iterations,
    required this.argon2Parallelism,
  });

  final Uint8List encryptedMnemonic;
  final Uint8List salt;
  final int argon2MemoryKib;
  final int argon2Iterations;
  final int argon2Parallelism;
}
