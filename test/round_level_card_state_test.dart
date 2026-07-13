import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
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
    final state = RoundLevelCardState(level: 5, round: round(), matrix: matrix);
    expect(state.fillPercent, 25);
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

  test('settled active ticket is completed and frozen takes precedence', () {
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
        frozen: true,
        level: 5,
        cellId: BigInt.one,
        cycleCount: BigInt.zero,
        totalWeight: BigInt.from(100),
      ),
    );
    expect(frozen.playerStatus, RoundLevelPlayerStatus.frozen);
  });
}
