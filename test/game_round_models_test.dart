import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';

void main() {
  final startsAt = DateTime.utc(2026, 7, 11, 12);
  final entriesCloseAt = startsAt.add(const Duration(hours: 1));
  final endsAt = startsAt.add(const Duration(hours: 2));

  GameRoundSchedule schedule({
    bool settled = false,
    bool cancelled = false,
    bool paused = false,
  }) {
    return GameRoundSchedule(
      seasonId: 1,
      roundId: 101,
      chainId: 84532,
      contractAddress: '0x1111111111111111111111111111111111111111',
      roundManagerAddress: '0x2222222222222222222222222222222222222222',
      level: 5,
      startsAt: startsAt,
      entriesCloseAt: entriesCloseAt,
      endsAt: endsAt,
      freezeClosesAt: entriesCloseAt,
      ethPriceWei: BigInt.from(200000000000000000),
      usdcPrice: BigInt.from(200000),
      maxPlayers: 1024,
      maxWinners: 4,
      freezeLimit: 10,
      paymentSplitVersion: 1,
      configHash: '0x${List.filled(32, '01').join()}',
      winningCellsRoot: '0x${List.filled(32, '02').join()}',
      operatorSignature: '0x${List.filled(65, '03').join()}',
      schemaVersion: 1,
      settled: settled,
      cancelled: cancelled,
      paused: paused,
    );
  }

  group('GameRoundSchedule phase boundaries', () {
    test('is scheduled before startsAt', () {
      expect(
        schedule().phaseAt(startsAt.subtract(const Duration(seconds: 1))),
        GameRoundPhase.scheduled,
      );
    });

    test('opens exactly at startsAt', () {
      expect(schedule().phaseAt(startsAt), GameRoundPhase.open);
    });

    test('locks exactly at entriesCloseAt', () {
      expect(schedule().phaseAt(entriesCloseAt), GameRoundPhase.locked);
    });

    test('becomes settlement-ready exactly at endsAt', () {
      expect(
        schedule().phaseAt(endsAt),
        GameRoundPhase.settlementReady,
      );
    });

    test('Firestore terminal flags do not override chain-derived time', () {
      expect(schedule(settled: true).phaseAt(startsAt), GameRoundPhase.open);
      expect(schedule(cancelled: true).phaseAt(startsAt), GameRoundPhase.open);
      expect(schedule(paused: true).phaseAt(startsAt), GameRoundPhase.open);
    });
  });

  test('view state never exposes a negative countdown', () {
    final state = GameRoundViewState.fromSchedule(
      schedule(),
      endsAt.add(const Duration(days: 1)),
    );
    expect(state.remaining, Duration.zero);
  });

  test('initialized chain config mismatch blocks entry', () {
    final chainState = GameRoundChainState(
      roundId: BigInt.from(101),
      configHash: '0x${List.filled(32, 'ff').join()}',
      initializedAt: startsAt,
      occupiedCells: BigInt.zero,
      winnersRegistered: BigInt.zero,
      initialized: true,
      settled: false,
      cancelled: false,
      paused: false,
      ethPriceWei: BigInt.from(200000000000000000),
      usdcPrice: BigInt.from(200000),
      phase: GameRoundPhase.open,
    );
    final state = GameRoundViewState.fromSchedule(
      schedule(),
      startsAt,
      chainState,
    );
    expect(state.isConfigurationTrusted, isFalse);
    expect(state.canEnter, isFalse);
  });

  test('duration formatter is stable', () {
    expect(
      formatRoundDuration(const Duration(days: 2, hours: 3, minutes: 4)),
      '02d 03h 04m 00s',
    );
  });
}
