import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';

void main() {
  final startsAt = DateTime.utc(2026, 7, 13, 12);

  GameRoundViewState round({
    GameRoundPhase phase = GameRoundPhase.open,
    int roundId = 501,
    bool trusted = true,
  }) {
    final schedule = GameRoundSchedule(
      seasonId: 1,
      roundId: roundId,
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
      isConfigurationTrusted: trusted,
    );
  }

  RoundPlayerState activePlayer() => RoundPlayerState(
        active: true,
        level: 5,
        cellId: BigInt.one,
        cycleCount: BigInt.zero,
        totalWeight: BigInt.from(100),
      );

  ArenaSkillStatus frozenStatus() => ArenaSkillStatus(
        frozen: true,
        immune: false,
        frozenUntil: startsAt.add(const Duration(hours: 1)),
        freezeHits: 1,
        freezeTokens: 0,
        unfreezePriceUsdc: BigInt.from(1000000),
      );

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

  test('level without a round does not invent a legacy core price', () {
    const state = RoundLevelCardState(level: 5);

    expect(state.ethPriceWei, BigInt.zero);
    expect(state.usdcPrice, BigInt.zero);
  });

  test('chance is derived from player and round total weight', () {
    final state = RoundLevelCardState(
      level: 5,
      round: round(),
      matrix: matrix,
      player: RoundPlayerState(
        active: true,
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

  test('missing schedule distinguishes loading from awaiting next game', () {
    const state = RoundLevelCardState(level: 5);

    expect(
      state.resolveViewMode(liveRound: null, isScheduleLoading: true),
      RoundLevelCardViewMode.scheduleLoading,
    );
    expect(
      state.resolveViewMode(liveRound: null, isScheduleLoading: false),
      RoundLevelCardViewMode.awaitingRound,
    );
  });

  test('stale and untrusted round data never exposes activation', () {
    final state = RoundLevelCardState(
      level: 5,
      round: round(),
      contractLevelAvailable: true,
    );

    expect(
      state.resolveViewMode(
        liveRound: round(roundId: 502),
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.refreshingRound,
    );
    expect(
      state.resolveViewMode(
        liveRound: round(trusted: false),
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.configurationMismatch,
    );
  });

  test('pending and failed player reads have explicit card states', () {
    final live = round();
    final pending = RoundLevelCardState(
      level: 5,
      round: live,
      playerStateResolved: false,
    );
    final failed = RoundLevelCardState(
      level: 5,
      round: live,
      errorMessage: 'rpc failed',
    );

    expect(
      pending.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.playerLoading,
    );
    expect(
      failed.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.dataError,
    );
  });

  test('scheduled timer is preserved until the entry window opens', () {
    final live = round(phase: GameRoundPhase.scheduled);
    final blocked = RoundLevelCardState(
      level: 5,
      round: live,
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.nextLevelRequired,
        requiredLevel: 4,
        blockingRoundId: BigInt.zero,
      ),
    );
    final missed = RoundLevelCardState(
      level: 5,
      round: live,
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.alreadyPurchasedOrLower,
        requiredLevel: 6,
        blockingRoundId: BigInt.zero,
      ),
    );

    expect(
      blocked.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.scheduled,
    );
    expect(
      missed.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.missed,
    );
  });

  test('open round resolves activation, active, freeze and progression modes',
      () {
    final live = round();
    final available = RoundLevelCardState(
      level: 5,
      round: live,
      contractLevelAvailable: true,
    );
    final active = RoundLevelCardState(
      level: 5,
      round: live,
      player: activePlayer(),
      contractLevelAvailable: true,
    );
    final frozen = RoundLevelCardState(
      level: 5,
      round: live,
      player: activePlayer(),
      arenaStatus: frozenStatus(),
      contractLevelAvailable: true,
    );
    final progressionBlocked = RoundLevelCardState(
      level: 5,
      round: live,
      contractLevelAvailable: true,
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.nextLevelRequired,
        requiredLevel: 4,
        blockingRoundId: BigInt.zero,
      ),
    );
    final progressionFrozen = RoundLevelCardState(
      level: 5,
      round: live,
      contractLevelAvailable: true,
      entryEligibility: RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.frozen,
        requiredLevel: 4,
        blockingRoundId: BigInt.one,
      ),
    );

    expect(
      available.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.activationAvailable,
    );
    expect(
      active.resolveViewMode(liveRound: live, isScheduleLoading: false),
      RoundLevelCardViewMode.active,
    );
    expect(
      frozen.resolveViewMode(liveRound: live, isScheduleLoading: false),
      RoundLevelCardViewMode.frozen,
    );
    expect(
      progressionBlocked.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.progressionBlocked,
    );
    expect(
      progressionFrozen.resolveViewMode(
        liveRound: live,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.progressionFrozen,
    );
  });

  test('closed and terminal phases preserve participant detail access', () {
    final locked = round(phase: GameRoundPhase.locked);
    final settlement = round(phase: GameRoundPhase.settlementReady);
    final settled = round(phase: GameRoundPhase.settled);

    expect(
      RoundLevelCardState(level: 5, round: locked).resolveViewMode(
        liveRound: locked,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.entryClosed,
    );
    expect(
      RoundLevelCardState(
        level: 5,
        round: locked,
        player: activePlayer(),
      ).resolveViewMode(liveRound: locked, isScheduleLoading: false),
      RoundLevelCardViewMode.entryClosedActive,
    );
    expect(
      RoundLevelCardState(
        level: 5,
        round: settlement,
        player: activePlayer(),
        arenaStatus: frozenStatus(),
      ).resolveViewMode(liveRound: settlement, isScheduleLoading: false),
      RoundLevelCardViewMode.settlementActive,
    );
    expect(
      RoundLevelCardState(level: 5, round: settled).resolveViewMode(
        liveRound: settled,
        isScheduleLoading: false,
      ),
      RoundLevelCardViewMode.settledWithoutEntry,
    );
    expect(
      RoundLevelCardState(
        level: 5,
        round: settled,
        player: activePlayer(),
      ).resolveViewMode(liveRound: settled, isScheduleLoading: false),
      RoundLevelCardViewMode.settledActive,
    );
  });

  test('administrative round phases override player freeze state', () {
    for (final entry in <GameRoundPhase, RoundLevelCardViewMode>{
      GameRoundPhase.paused: RoundLevelCardViewMode.paused,
      GameRoundPhase.cancelled: RoundLevelCardViewMode.cancelled,
      GameRoundPhase.uninitialized: RoundLevelCardViewMode.uninitialized,
    }.entries) {
      final live = round(phase: entry.key);
      final state = RoundLevelCardState(
        level: 5,
        round: live,
        player: activePlayer(),
        arenaStatus: frozenStatus(),
      );
      expect(
        state.resolveViewMode(
          liveRound: live,
          isScheduleLoading: false,
        ),
        entry.value,
      );
    }
  });
}
