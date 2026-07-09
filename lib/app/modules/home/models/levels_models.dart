import 'package:lottery_advance/app/services/wallet_connect_service.dart';

const int easyGameLevelCount = 17;

double levelPrice(int level) {
  const prices = {
    1: 0.05,
    2: 0.07,
    3: 0.1,
    4: 0.14,
    5: 0.2,
    6: 0.28,
    7: 0.4,
    8: 0.55,
    9: 0.8,
    10: 1.1,
    11: 1.6,
    12: 2.2,
    13: 3.2,
    14: 4.4,
    15: 6.5,
    16: 8.0,
    17: 12.0,
  };
  return prices[level] ?? 0.05;
}


String formatUsdc(BigInt amount, {int decimals = 2}) {
  final base = BigInt.from(10).pow(6); // USDC имеет 6 дециклов
  final whole = amount ~/ base;
  final fraction = (amount % base).toString().padLeft(6, '0');
  final clipped = fraction.substring(0, decimals);
  final trimmed = clipped.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
}

String formatWeiToEth(BigInt wei, {int decimals = 4}) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = (wei % base).toString().padLeft(18, '0');
  final clipped = fraction.substring(0, decimals);
  final trimmed = clipped.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
}

String formatBpsToPercent(BigInt bps, {int decimals = 2}) {
  final value = bps.toDouble() / 100;
  return '${value.toStringAsFixed(decimals).replaceFirst(RegExp(r'\.?0+$'), '')}%';
}

double weiToEthDouble(BigInt wei) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = wei % base;
  return whole.toDouble() + fraction.toDouble() / base.toDouble();
}

enum LevelStatus { locked, frozen, active, waiting, completed }

class Level {
  final int levelNumber;
  LevelStatus status;
  double coin;
  double partnerBonus;
  double levelProfit;
  double fillPercent;
  bool isVisible;
  late BigInt cycles;
  late BigInt positionId;
  late BigInt earnedWei;
  late BigInt matrixSize;
  late BigInt prizePoolWei;
  late BigInt totalWeight;
  late BigInt activeCells;
  late BigInt playerWeight;
  late BigInt playerChanceBps;

  Level({
    required this.levelNumber,
    required this.status,
    required this.coin,
    required this.partnerBonus,
    required this.levelProfit,
    required this.fillPercent,
    required this.isVisible,
    BigInt? cycles,
    BigInt? positionId,
    BigInt? earnedWei,
    BigInt? matrixSize,
    BigInt? prizePoolWei,
    BigInt? totalWeight,
    BigInt? activeCells,
    BigInt? playerWeight,
    BigInt? playerChanceBps,
  }) {
    this.cycles = cycles ?? BigInt.zero;
    this.positionId = positionId ?? BigInt.zero;
    this.earnedWei = earnedWei ?? BigInt.zero;
    this.matrixSize = matrixSize ?? BigInt.zero;
    this.prizePoolWei = prizePoolWei ?? BigInt.zero;
    this.totalWeight = totalWeight ?? BigInt.zero;
    this.activeCells = activeCells ?? BigInt.zero;
    this.playerWeight = playerWeight ?? BigInt.zero;
    this.playerChanceBps = playerChanceBps ?? BigInt.zero;
  }

  // Example for JSON serialization
  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'status': status.toString(),
        'coin': coin,
        'partnerBonus': partnerBonus,
        'levelProfit': levelProfit,
        'fillPercent': fillPercent,
        'isVisible': isVisible,
        'cycles': cycles.toString(),
        'positionId': positionId.toString(),
        'earnedWei': earnedWei.toString(),
        'matrixSize': matrixSize.toString(),
        'prizePoolWei': prizePoolWei.toString(),
        'totalWeight': totalWeight.toString(),
        'activeCells': activeCells.toString(),
        'playerWeight': playerWeight.toString(),
        'playerChanceBps': playerChanceBps.toString(),
      };

  factory Level.fromJson(Map<String, dynamic> json) => Level(
        levelNumber: json['levelNumber'],
        status: LevelStatus.values
            .firstWhere((e) => e.toString() == json['status']),
        coin: json['coin'],
        partnerBonus: json['partnerBonus'],
        levelProfit: json['levelProfit'],
        fillPercent: json['fillPercent'],
        isVisible: json['isVisible'],
        cycles: BigInt.tryParse('${json['cycles'] ?? 0}') ?? BigInt.zero,
        positionId:
            BigInt.tryParse('${json['positionId'] ?? 0}') ?? BigInt.zero,
        earnedWei: BigInt.tryParse('${json['earnedWei'] ?? 0}') ?? BigInt.zero,
        matrixSize:
            BigInt.tryParse('${json['matrixSize'] ?? 0}') ?? BigInt.zero,
        prizePoolWei:
            BigInt.tryParse('${json['prizePoolWei'] ?? 0}') ?? BigInt.zero,
        totalWeight:
            BigInt.tryParse('${json['totalWeight'] ?? 0}') ?? BigInt.zero,
        activeCells:
            BigInt.tryParse('${json['activeCells'] ?? 0}') ?? BigInt.zero,
        playerWeight:
            BigInt.tryParse('${json['playerWeight'] ?? 0}') ?? BigInt.zero,
        playerChanceBps:
            BigInt.tryParse('${json['playerChanceBps'] ?? 0}') ?? BigInt.zero,
      );
}

class LevelDetailSnapshot {
  final EasyGameLevelState state;
  final EasyGameMatrixStats stats;
  final EasyGameAdvanceLevelStats advanceStats;
  final BigInt priceWei;
  final EasyGamePlayerSummary? player;
  final BigInt playerWeight;
  final BigInt playerChanceBps;

  const LevelDetailSnapshot({
    required this.state,
    required this.stats,
    required this.advanceStats,
    required this.priceWei,
    required this.player,
    required this.playerWeight,
    required this.playerChanceBps,
  });
}

class DetailRow {
  final String label;
  final String value;

  const DetailRow(this.label, this.value);
}

String formatLevelPrice(double value) {
  final fixed = value.toStringAsFixed(3);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
