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

  test('round with chain state uses on-chain price', () {
    final manifestRound = round();
    final chainState = GameRoundChainState(
      roundId: BigInt.from(501),
      configHash: manifestRound.schedule.configHash,
      committedConfigHash: manifestRound.schedule.configHash,
      seasonConfigRoot: '0x${List.filled(32, 'aa').join()}',
      seasonCommitted: true,
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

  test('level without a round returns zero prices', () {
    const state = RoundLevelCardState(level: 5);
    expect(state.ethPriceWei, BigInt.zero);
    expect(state.usdcPrice, BigInt.zero);
  });

  test('weight share is derived from player and round total weight', () {
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
    expect(state.playerWeightShareBps, BigInt.from(2500));
    expect(state.resolveViewMode(), RoundLevelCardViewMode.active);
  });

  test('active player in settled phase is completed', () {
    final settled = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.settled),
      player: activePlayer(),
    );
    expect(settled.resolveViewMode(), RoundLevelCardViewMode.completed);
  });

  test('frozen overrides active during live phases', () {
    for (final phase in [GameRoundPhase.open, GameRoundPhase.locked,
                         GameRoundPhase.settlementReady, GameRoundPhase.settled]) {
      final state = RoundLevelCardState(
        level: 5,
        round: round(phase: phase),
        player: activePlayer(),
        arenaStatus: frozenStatus(),
      );
      expect(state.resolveViewMode(), RoundLevelCardViewMode.frozen);
    }
  });

  test('admin phases take priority over frozen', () {
    final paused = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.paused),
      player: activePlayer(),
      arenaStatus: frozenStatus(),
    );
    expect(paused.resolveViewMode(), RoundLevelCardViewMode.paused);

    final cancelled = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.cancelled),
      player: activePlayer(),
      arenaStatus: frozenStatus(),
    );
    expect(cancelled.resolveViewMode(), RoundLevelCardViewMode.cancelled);

    final scheduled = RoundLevelCardState(
      level: 5,
      round: round(phase: GameRoundPhase.scheduled),
      player: activePlayer(),
      arenaStatus: frozenStatus(),
    );
    expect(scheduled.resolveViewMode(), RoundLevelCardViewMode.awaiting);
  });

  test('direct invites and capacity from season progress', () {
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

  group('resolveViewMode', () {
    test('without round returns awaiting', () {
      const state = RoundLevelCardState(level: 5);
      expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
    });

    test('scheduled round returns awaiting', () {
      final state = RoundLevelCardState(
        level: 5,
        round: round(phase: GameRoundPhase.scheduled),
      );
      expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
    });

    test('uninitialized round returns awaiting', () {
      final state = RoundLevelCardState(
        level: 5,
        round: round(phase: GameRoundPhase.uninitialized),
      );
      expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
    });

    test('paused returns paused', () {
      final state = RoundLevelCardState(
        level: 5,
        round: round(phase: GameRoundPhase.paused),
      );
      expect(state.resolveViewMode(), RoundLevelCardViewMode.paused);
    });

    test('cancelled returns cancelled', () {
      final state = RoundLevelCardState(
        level: 5,
        round: round(phase: GameRoundPhase.cancelled),
      );
      expect(state.resolveViewMode(), RoundLevelCardViewMode.cancelled);
    });

    group('open phase', () {
      test('active player returns active', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(),
          player: activePlayer(),
          contractLevelAvailable: true,
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.active);
      });

      test('inactive player who can enter returns activation', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(),
          contractLevelAvailable: true,
          entryEligibility: RoundEntryEligibility.eligible,
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.activation);
      });

      test('inactive player who missed level returns activation', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(),
          contractLevelAvailable: true,
          entryEligibility: RoundEntryEligibility(
            reason: RoundEntryEligibilityReason.alreadyPurchasedOrLower,
            requiredLevel: 6,
            blockingRoundId: BigInt.zero,
          ),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.activation);
      });

      test('inactive player blocked by progression returns activation', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(),
          contractLevelAvailable: true,
          entryEligibility: RoundEntryEligibility(
            reason: RoundEntryEligibilityReason.nextLevelRequired,
            requiredLevel: 4,
            blockingRoundId: BigInt.zero,
          ),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.activation);
      });

      test('frozen without entry returns frozen', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(),
          arenaStatus: frozenStatus(),
          contractLevelAvailable: true,
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.frozen);
      });
    });

    group('locked phase', () {
      test('active player returns active', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.locked),
          player: activePlayer(),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.active);
      });

      test('inactive player returns awaiting', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.locked),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
      });
    });

    group('settlementReady phase', () {
      test('active player returns active', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.settlementReady),
          player: activePlayer(),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.active);
      });

      test('inactive player returns awaiting', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.settlementReady),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
      });
    });

    group('settled phase', () {
      test('active player returns completed', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.settled),
          player: activePlayer(),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.completed);
      });

      test('inactive player returns awaiting', () {
        final state = RoundLevelCardState(
          level: 5,
          round: round(phase: GameRoundPhase.settled),
        );
        expect(state.resolveViewMode(), RoundLevelCardViewMode.awaiting);
      });
    });
  });
}
