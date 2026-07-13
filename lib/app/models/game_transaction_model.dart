class GameTransaction {
  final String id;
  final int chainId;
  final String transactionHash;
  final String wallet;
  final String status;
  final String operation;
  final int? level;
  final String amount;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GameTransaction({
    required this.id,
    required this.chainId,
    required this.transactionHash,
    required this.wallet,
    required this.status,
    required this.operation,
    required this.level,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isConfirmed => status == 'confirmed' || status == 'fulfilled';

  bool get isFailed => status == 'failed' || status == 'reverted';

  String get shortHash => _shortAddress(transactionHash);

  String get shortWallet => _shortAddress(wallet);

  static String _shortAddress(String value) {
    if (value.length <= 13) return value;
    return '${value.substring(0, 7)}...${value.substring(value.length - 4)}';
  }
}
