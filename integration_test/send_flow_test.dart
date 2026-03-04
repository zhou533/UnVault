import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unvault/src/rust/api/transaction_api.dart' as tx;
import 'package:unvault/src/rust/api/wallet_api.dart' as wallet;
import 'package:unvault/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  // ---------- shared test constants ----------

  // Well-known BIP-39 test vector mnemonic
  // (account 0 address is deterministic).
  final phraseBytes =
      'abandon abandon abandon abandon abandon abandon abandon abandon '
              'abandon abandon abandon about'
          .codeUnits;

  const toAddress = '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045';
  final chainId = BigInt.from(1);
  final nonce = BigInt.zero;
  const valueWei = '1000000000000000000'; // 1 ETH
  final gasLimit = BigInt.from(21000);
  final maxFeePerGas = BigInt.from(30000000000);
  final maxPriorityFeePerGas = BigInt.from(2000000000);

  // ---------- tests ----------

  test('create wallet via FFI returns valid response', () async {
    final password = Uint8List.fromList('integration_test_pw!'.codeUnits);

    final response = await wallet.createWallet(
      password: password,
      wordCount: 12,
    );

    expect(response.firstAddress, startsWith('0x'));
    expect(response.firstAddress.length, equals(42));
    expect(response.salt.length, equals(16));
    expect(response.encryptedMnemonic, isNotEmpty);
    expect(response.mnemonicBytes, isNotEmpty);
  });

  test('derive accounts returns valid Ethereum addresses', () {
    final accounts = wallet.deriveAccounts(
      phraseBytes: phraseBytes,
      count: 1,
    );

    expect(accounts, hasLength(1));
    expect(accounts.first, startsWith('0x'));
    expect(accounts.first.length, equals(42));
  });

  test('sign transaction with seed returns valid result', () async {
    final result = await tx.signTransactionWithSeed(
      phraseBytes: phraseBytes,
      accountIndex: 0,
      chainId: chainId,
      nonce: nonce,
      to: toAddress,
      valueWei: valueWei,
      input: const <int>[],
      gasLimit: gasLimit,
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );

    // rawTx must be non-empty RLP bytes.
    expect(result.rawTx, isNotEmpty);

    // txHash must be exactly 32 bytes (Keccak-256).
    expect(result.txHash.length, equals(32));

    // from must be a valid checksummed Ethereum address.
    expect(result.from, startsWith('0x'));
    expect(result.from.length, equals(42));
  });

  test('decrypt mnemonic roundtrip matches original', () async {
    final password = Uint8List.fromList('roundtrip_password!'.codeUnits);

    // Create a wallet to get encrypted mnemonic.
    final creation = await wallet.createWallet(
      password: password,
      wordCount: 12,
    );

    // Decrypt with the same password.
    final decrypted = await wallet.decryptMnemonic(
      password: password,
      encryptedMnemonic: creation.encryptedMnemonic,
      salt: creation.salt,
      memoryKib: creation.argon2MemoryKib,
      iterations: creation.argon2Iterations,
      parallelism: creation.argon2Parallelism,
    );

    expect(decrypted, equals(creation.mnemonicBytes));
  });

  test(
    'different account indices produce different from addresses',
    () async {
      final result0 = await tx.signTransactionWithSeed(
        phraseBytes: phraseBytes,
        accountIndex: 0,
        chainId: chainId,
        nonce: nonce,
        to: toAddress,
        valueWei: valueWei,
        input: const <int>[],
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
      );

      final result1 = await tx.signTransactionWithSeed(
        phraseBytes: phraseBytes,
        accountIndex: 1,
        chainId: chainId,
        nonce: nonce,
        to: toAddress,
        valueWei: valueWei,
        input: const <int>[],
        gasLimit: gasLimit,
        maxFeePerGas: maxFeePerGas,
        maxPriorityFeePerGas: maxPriorityFeePerGas,
      );

      // Same mnemonic, different BIP-44 account index → different sender.
      expect(result0.from, isNot(equals(result1.from)));

      // Both must still be valid Ethereum addresses.
      expect(result0.from, startsWith('0x'));
      expect(result1.from, startsWith('0x'));
      expect(result0.from.length, equals(42));
      expect(result1.from.length, equals(42));
    },
  );
}
