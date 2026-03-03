// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'UnVault';

  @override
  String get walletListTitle => 'Wallets';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get importWallet => 'Import Wallet';

  @override
  String get unlock => 'Unlock';

  @override
  String get setPassword => 'Set Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get biometricSetup => 'Biometric Setup';

  @override
  String get backupMnemonic => 'Backup Mnemonic';

  @override
  String get verifyMnemonic => 'Verify Mnemonic';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get confirmTransaction => 'Confirm Transaction';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get settings => 'Settings';

  @override
  String get networkManagement => 'Network Management';
}
