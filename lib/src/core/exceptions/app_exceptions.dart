sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PasswordTooShortException extends AppException {
  const PasswordTooShortException()
      : super('Password must be at least 8 characters');
}

class WalletNotFoundException extends AppException {
  const WalletNotFoundException() : super('Wallet not found');
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class RustBridgeException extends AppException {
  const RustBridgeException(super.message);
}

class WalletLimitException extends AppException {
  const WalletLimitException()
      : super('Maximum of 10 wallets reached');
}
