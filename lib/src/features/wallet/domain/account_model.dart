class AccountModel {
  const AccountModel({
    required this.id,
    required this.walletId,
    required this.derivationIndex,
    required this.address,
    this.name,
  });

  final int id;
  final int walletId;
  final int derivationIndex;
  final String address;
  final String? name;
}
