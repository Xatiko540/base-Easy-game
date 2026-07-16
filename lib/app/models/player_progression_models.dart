enum RoundEntryEligibilityReason {
  eligible,
  alreadyPurchasedOrLower,
  nextLevelRequired,
  frozen,
  unknown,
}

RoundEntryEligibilityReason roundEntryEligibilityReasonFromContractValue(
  int value,
) {
  if (value < 0 || value > RoundEntryEligibilityReason.frozen.index) {
    return RoundEntryEligibilityReason.unknown;
  }
  return RoundEntryEligibilityReason.values[value];
}

class PlayerSeasonProgress {
  final bool started;
  final int startLevel;
  final int highestLevel;
  final int activatedLevels;
  final int directInvites;
  final int inviteCapacity;

  const PlayerSeasonProgress({
    required this.started,
    required this.startLevel,
    required this.highestLevel,
    required this.activatedLevels,
    required this.directInvites,
    required this.inviteCapacity,
  });

  static const empty = PlayerSeasonProgress(
    started: false,
    startLevel: 0,
    highestLevel: 0,
    activatedLevels: 0,
    directInvites: 0,
    inviteCapacity: 0,
  );

  int get remainingInviteSlots =>
      (inviteCapacity - directInvites).clamp(0, inviteCapacity);

  int? get nextLevel =>
      !started || highestLevel >= 17 ? null : highestLevel + 1;
}

class RoundEntryEligibility {
  final RoundEntryEligibilityReason reason;
  final int requiredLevel;
  final BigInt blockingRoundId;

  const RoundEntryEligibility({
    required this.reason,
    required this.requiredLevel,
    required this.blockingRoundId,
  });

  static final eligible = RoundEntryEligibility(
    reason: RoundEntryEligibilityReason.eligible,
    requiredLevel: 0,
    blockingRoundId: BigInt.zero,
  );

  bool get canEnter => reason == RoundEntryEligibilityReason.eligible;
}
