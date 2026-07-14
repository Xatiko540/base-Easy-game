import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_phase.dart';

export 'package:lottery_advance/app/models/game_round_phase.dart';

class GameRoundSchedule {
  final int seasonId;
  final int roundId;
  final int chainId;
  final String contractAddress;
  final String roundManagerAddress;
  final int level;
  final DateTime startsAt;
  final DateTime entriesCloseAt;
  final DateTime endsAt;
  final DateTime freezeClosesAt;
  final BigInt ethPriceWei;
  final BigInt usdcPrice;
  final int maxPlayers;
  final int maxWinners;
  final int freezeLimit;
  final int paymentSplitVersion;
  final String configHash;
  final String winningCellsRoot;
  final String operatorSignature;
  final int schemaVersion;
  final bool initialized;
  final bool settled;
  final bool cancelled;
  final bool paused;

  const GameRoundSchedule({
    required this.seasonId,
    required this.roundId,
    required this.chainId,
    required this.contractAddress,
    required this.roundManagerAddress,
    required this.level,
    required this.startsAt,
    required this.entriesCloseAt,
    required this.endsAt,
    required this.freezeClosesAt,
    required this.ethPriceWei,
    required this.usdcPrice,
    required this.maxPlayers,
    required this.maxWinners,
    required this.freezeLimit,
    required this.paymentSplitVersion,
    required this.configHash,
    required this.winningCellsRoot,
    required this.operatorSignature,
    required this.schemaVersion,
    this.initialized = false,
    this.settled = false,
    this.cancelled = false,
    this.paused = false,
  });

  factory GameRoundSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Round document has no data');
    }

    return GameRoundSchedule.fromMap(
      documentId: doc.id,
      data: data,
    );
  }

  factory GameRoundSchedule.fromMap({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final config = _map(data['config']);
    final state = _map(data['state']);
    final schedule = config.isEmpty ? data : config;

    final startsAt = _date(schedule['startsAt']);
    final entriesCloseAt = _date(schedule['entriesCloseAt']);
    final endsAt = _date(schedule['endsAt']);
    final freezeClosesAt = _date(
      schedule['freezeClosesAt'] ?? schedule['entriesCloseAt'],
    );

    if (!startsAt.isBefore(entriesCloseAt) ||
        !entriesCloseAt.isBefore(endsAt)) {
      throw FormatException('Invalid round time boundaries in $documentId');
    }

    final round = GameRoundSchedule(
      seasonId: _integer(schedule['seasonId']),
      roundId: _integer(schedule['roundId']),
      chainId: _integer(schedule['chainId'] ?? data['chainId']),
      contractAddress:
          '${schedule['contractAddress'] ?? data['contractAddress'] ?? ''}'
              .toLowerCase(),
      roundManagerAddress:
          '${schedule['roundManagerAddress'] ?? data['roundManagerAddress'] ?? ''}'
              .toLowerCase(),
      level: _integer(schedule['level']),
      startsAt: startsAt,
      entriesCloseAt: entriesCloseAt,
      endsAt: endsAt,
      freezeClosesAt: freezeClosesAt,
      ethPriceWei: _bigInt(schedule['ethPriceWei']),
      usdcPrice: _bigInt(schedule['usdcPrice']),
      maxPlayers: _integer(schedule['maxPlayers']),
      maxWinners: _integer(schedule['maxWinners']),
      freezeLimit: _integer(schedule['freezeLimit']),
      paymentSplitVersion: _integer(schedule['paymentSplitVersion']),
      configHash: '${data['configHash'] ?? ''}',
      winningCellsRoot:
          '${schedule['winningCellsRoot'] ?? data['winningCellsRoot'] ?? ''}',
      operatorSignature: '${data['operatorSignature'] ?? ''}',
      schemaVersion: _integer(data['schemaVersion'], fallback: 1),
      initialized: state['initialized'] as bool? ?? false,
      settled: state['settled'] as bool? ?? false,
      cancelled: state['cancelled'] as bool? ?? false,
      paused: state['paused'] as bool? ?? false,
    );

    round.validate();
    return round;
  }

  void validate() {
    if (seasonId <= 0 || roundId <= 0) {
      throw const FormatException('Season and round IDs must be positive');
    }
    if (level < 1 || level > 17) {
      throw FormatException('Invalid round level: $level');
    }
    if (chainId <= 0 ||
        contractAddress.isEmpty ||
        roundManagerAddress.isEmpty) {
      throw const FormatException('Round chain identity is incomplete');
    }
    if (freezeClosesAt.isAfter(endsAt)) {
      throw const FormatException('Freeze window cannot outlive the round');
    }
    if (maxPlayers <= 0 ||
        maxWinners <= 0 ||
        maxWinners > 8 ||
        freezeLimit <= 0) {
      throw const FormatException('Invalid round capacity');
    }
    if (paymentSplitVersion != 1) {
      throw FormatException(
        'Unsupported payment split version: $paymentSplitVersion',
      );
    }
    if (!_isHex(configHash, 32) || !_isHex(winningCellsRoot, 32)) {
      throw const FormatException('Invalid round hash or winning-cells root');
    }
    if (!_isHex(operatorSignature, 65)) {
      throw const FormatException('Invalid round operator signature');
    }
  }

  GameRoundPhase phaseAt(DateTime chainTime) {
    final now = chainTime.toUtc();
    if (now.isBefore(startsAt.toUtc())) return GameRoundPhase.scheduled;
    if (now.isBefore(entriesCloseAt.toUtc())) return GameRoundPhase.open;
    if (now.isBefore(endsAt.toUtc())) return GameRoundPhase.locked;
    return GameRoundPhase.settlementReady;
  }

  DateTime? phaseDeadline(GameRoundPhase phase) {
    switch (phase) {
      case GameRoundPhase.scheduled:
        return startsAt;
      case GameRoundPhase.open:
        return entriesCloseAt;
      case GameRoundPhase.locked:
        return endsAt;
      case GameRoundPhase.uninitialized:
      case GameRoundPhase.settlementReady:
      case GameRoundPhase.settled:
      case GameRoundPhase.cancelled:
      case GameRoundPhase.paused:
        return null;
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is int) {
      final milliseconds = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) {
      throw FormatException('Invalid round timestamp: $value');
    }
    return parsed.toUtc();
  }

  static int _integer(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static BigInt _bigInt(dynamic value) =>
      BigInt.tryParse('${value ?? 0}') ?? BigInt.zero;

  static bool _isHex(String value, int bytes) => RegExp(
        '^0x[0-9a-fA-F]{${bytes * 2}}\$',
      ).hasMatch(value);
}

class GameRoundViewState {
  final GameRoundSchedule schedule;
  final GameRoundPhase phase;
  final Duration remaining;
  final GameRoundChainState? chainState;
  final bool isConfigurationTrusted;

  const GameRoundViewState({
    required this.schedule,
    required this.phase,
    required this.remaining,
    this.chainState,
    required this.isConfigurationTrusted,
  });

  factory GameRoundViewState.fromSchedule(
      GameRoundSchedule schedule, DateTime chainTime,
      [GameRoundChainState? chainState]) {
    final chainInitialized = chainState?.initialized == true;
    final configMatches = !chainInitialized ||
        _normalizedHash(chainState!.configHash) ==
            _normalizedHash(schedule.configHash);
    final phase =
        chainInitialized ? chainState!.phase : schedule.phaseAt(chainTime);
    final deadline = schedule.phaseDeadline(phase);
    final remaining = deadline == null
        ? Duration.zero
        : deadline.difference(chainTime.toUtc());
    return GameRoundViewState(
      schedule: schedule,
      phase: phase,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      chainState: chainState,
      isConfigurationTrusted: configMatches,
    );
  }

  bool get canEnter => isConfigurationTrusted && phase == GameRoundPhase.open;

  String get countdownLabel => formatRoundDuration(remaining);
}

String _normalizedHash(String value) => value.trim().toLowerCase();

String formatRoundDuration(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final days = safe.inDays;
  final hours = safe.inHours.remainder(24);
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  return '${days.toString().padLeft(2, '0')}d '
      '${hours.toString().padLeft(2, '0')}h '
      '${minutes.toString().padLeft(2, '0')}m '
      '${seconds.toString().padLeft(2, '0')}s';
}
