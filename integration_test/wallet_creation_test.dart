import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unvault/src/rust/api/crypto_api.dart' as crypto;
import 'package:unvault/src/rust/api/wallet_api.dart' as wallet;
import 'package:unvault/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  test('FRB bridge: generate and validate mnemonic roundtrip', () async {
    final mnemonicBytes = crypto.generateMnemonic(wordCount: 12);
    expect(mnemonicBytes.length, greaterThan(0));

    final isValid = crypto.validateMnemonic(phraseBytes: mnemonicBytes);
    expect(isValid, isTrue);
  });

  test('FRB bridge: create wallet returns valid address', () async {
    final response = await wallet.createWallet(
      password: Uint8List.fromList('test_password_123'.codeUnits),
      wordCount: 12,
    );

    expect(response.firstAddress, startsWith('0x'));
    expect(response.firstAddress.length, equals(42));
    expect(response.salt.length, equals(16));
    expect(response.encryptedMnemonic, isNotEmpty);
  });
}
