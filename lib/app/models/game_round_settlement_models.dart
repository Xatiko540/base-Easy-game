class RoundWinningCellProof {
  final BigInt cellId;
  final List<String> proof;

  const RoundWinningCellProof({required this.cellId, required this.proof});

  factory RoundWinningCellProof.fromJson(Map<String, dynamic> json) {
    return RoundWinningCellProof(
      cellId: BigInt.parse('${json['cellId']}'),
      proof: List<String>.from(json['proof'] as List? ?? const []),
    );
  }
}

class RoundSettlementProofs {
  final BigInt roundId;
  final List<RoundWinningCellProof> cells;

  const RoundSettlementProofs({required this.roundId, required this.cells});
}

class SettlementClaimable {
  final BigInt ethAmount;
  final BigInt usdcAmount;

  const SettlementClaimable(
      {required this.ethAmount, required this.usdcAmount});

  static final zero = SettlementClaimable(
    ethAmount: BigInt.zero,
    usdcAmount: BigInt.zero,
  );

  bool get hasReward => ethAmount > BigInt.zero || usdcAmount > BigInt.zero;
}
