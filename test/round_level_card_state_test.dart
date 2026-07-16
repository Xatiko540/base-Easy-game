import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';

void main() {
  final startsAt = DateTime.utc(2026, 7, 13, 12);

  GameRoundViewState round({GameRoundPhase phase = GameRoundPhase.open}) {
    final schedule = GameRoundSchedule(
      seasonId: 1,
      roundId: 501,
      chainId: 84532,
      contractAddress: '0x1111111111111111111111111111111111111111',
      roundManagerAddress: '0x2222222222222222222222222222222222222222',
      level: 5,
      startsAt: startsAt,
      entriesCloseAt: startsAt.add(const Duration(hours: 1)),
      endsAt: startsAt.add(const Duration(hours: 2)),
      freezeClosesAt: startsAt.add(const Duration(hours: 1)),
      ethPriceWei: BigInt.from(200000000000000000),
      usdcPrice: BigInt.from(200000),
      maxPlayers: 100,
      maxWinners: 4,
      freezeLimit: 10,
      paymentSplitVersion: 1,
      configHash: '0x${List.filled(64, '1').join()}',
      winningCellsRoot: '0x${List.filled(64, '2').join()}',
      operatorSignature: '0x${List.filled(130, '3').join()}',
      schemaVersion: 1,
    );
    return GameRoundViewState(
      schedule: schedule,
      phase: phase,
      remaining: Duration.zero,
      isConfigurationTrusted: true,
    );
  }

  final matrix = RoundMatrixStats(
    prizePoolEth: BigInt.zero,
    prizePoolUsdc: BigInt.zero,
    totalWeight: BigInt.from(1000),
    activeCells: BigInt.from(25),
    nextCellId: BigInt.from(26),
    nextOpenParentId: BigInt.from(13),
  );

  test('progress uses occupied round cells and manifest capacity', () {
    final state = RoundLevelCardState(
      level: 5,
      round: round(),
      matrix: matrix,
      contractLevelAvailable: true,
    );
    expect(state.fillPercent, 25);
  });

  test('initialized round uses prices read from the round manager', () {
    final manifestRound = round();
    final chainState = GameRoundChainState(
      roundId: BigInt.from(501),
      configHash: manifestRound.schedule.configHash,
      initializedAt: startsAt,
      occupiedCells: BigInt.zero,
      winnersRegistered: BigInt.zero,
      initialized: true,
      settled: false,
      cancelled: false,
      paused: false,
      prizePoolEth: BigInt.zero,
      prizePoolUsdc: BigInt.zero,
      ethPriceWei: BigInt.from(210000000000000000),
      usdcPrice: BigInt.from(210000),
      phase: GameRoundPhase.open,
    );
    final trustedRound = GameRoundViewState.fromSchedule(
      manifestRound.schedule,
      startsAt,
      chainState,
    );
    final state = RoundLevelCardState(level: 5, round: trustedRound);

    expect(state.ethPriceWei, BigInt.from(210000000000000000));
    expect(state.usdcPrice, BigInt.from(210000));
  });

  test('level without a round exposes fallback prices read from core', () {
    final state = RoundLevelCardState(
      level: 5,
      contractEthPriceWei: BigInt.from(200000000000000000),
      contractUsdcPrice: BigInt.from(200000),
    );

    expect(state.ethPriceWei, BigInt.from(200000000000000000));
    expect(state.usdcPrice, BigInt.from(200000));
  });

  test('chance is derived from player and round total weight', () {
    final state = RoundLevelCardState(
      level: 5,
      round: round(),
      matrix: matrix,
      player: RoundPlayerState(
        active: true,
        frozen: false,
        level: 5,
        cellId: BigInt.one,
        cycleCount: BigInt.zero,
        totalWeight: BigInt.from(250),
      ),
    );
    expect(state.playerChanceBps, BigInt.from(2500));
    expect(state.playerStatus, RoundLevelPlayerStatus.active);
  });

  test('only arena freeze marks an active ticket as frozen', () {
    final settled = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.settled),
      player: RoundPlayerState(
        active: true,
        frozen: false,
        level: 5,
        cellId: BigInt.one,
        cycleCount: BigInt.zero,
        totalWeight: BigInt.from(100),
      ),
    );
    expect(settled.playerStatus, RoundLevelPlayerStatus.completed);

    final frozen = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.settled),
      player: RoundPlayerState(
        active: true,
        frozen: false,
        level: 5,
        cellId: BigInt.one,
        cycleCount: BigInt.zero,
        totalWeight: BigInt.from(100),
      ),
      arenaStatus: ArenaSkillStatus(
        frozen: true,
        immune: false,
        frozenUntil: startsAt.add(const Duration(hours: 1)),
        freezeHits: 1,
        freezeTokens: 0,
        unfreezePriceUsdc: BigInt.from(1000000),
      ),
    );
    expect(frozen.playerStatus, RoundLevelPlayerStatus.frozen);
  });

  test('four direct partners are granted for every activated level', () {
    const progress = PlayerSeasonProgress(
      started: true,
      startLevel: 3,
      highestLevel: 4,
      activatedLevels: 2,
      directInvites: 5,
      inviteCapacity: 8,
    );
    final state = RoundLevelCardState(
      level: 4,
      round: round(),
      seasonProgress: progress,
    );

    expect(state.directInvites, 5);
    expect(state.inviteCapacity, 8);
    expect(state.remainingInviteSlots, 3);
  });

  test('progression eligibility distinguishes missed and locked levels', () {
    final missed = RoundLevelCardState(
      level: 2,
      round: round(),
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.alreadyPurchasedOrLower,
        requiredLevel: 3,
        blockingRoundId: BigInt.zero,
      ),
    );
    final locked = RoundLevelCardState(
      level: 5,
      round: round(),
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.nextLevelRequired,
        requiredLevel: 4,
        blockingRoundId: BigInt.zero,
      ),
    );

    expect(missed.playerStatus, RoundLevelPlayerStatus.missed);
    expect(locked.playerStatus, RoundLevelPlayerStatus.progressionBlocked);
    expect(locked.requiredLevel, 4);
  });

  test('emergency pause blocks an otherwise open round', () {
    final state = RoundLevelCardState(
      level: 5,
      round: round(),
      contractLevelAvailable: false,
    );

    expect(state.isEmergencyPaused, isTrue);
    expect(state.canEnter, isFalse);
    expect(state.playerStatus, RoundLevelPlayerStatus.unavailable);
  });
}
