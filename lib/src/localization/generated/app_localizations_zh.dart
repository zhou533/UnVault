// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'UnVault';

  @override
  String get walletListTitle => '钱包';

  @override
  String get createWallet => '创建钱包';

  @override
  String get importWallet => '导入钱包';

  @override
  String get unlock => '解锁';

  @override
  String get setPassword => '设置密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get biometricSetup => '生物识别设置';

  @override
  String get backupMnemonic => '备份助记词';

  @override
  String get verifyMnemonic => '验证助记词';

  @override
  String get send => '发送';

  @override
  String get receive => '收款';

  @override
  String get confirmTransaction => '确认交易';

  @override
  String get transactionHistory => '交易记录';

  @override
  String get settings => '设置';

  @override
  String get networkManagement => '网络管理';
}
