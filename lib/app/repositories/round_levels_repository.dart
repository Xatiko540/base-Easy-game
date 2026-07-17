import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class RoundLevelsRepository extends GetxService {
  final WalletConnectService _wallet = Get.find<WalletConnectService>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();

  bool? _progressionQueriesSupported;
  DateTime? _progressionRetryAfter;

  Future<List<RoundLevelCardState>> loadCards({
    String? playerAddress,
    void Function(List<RoundLevelCardState> batch)? onBatch,
  }) async {
    final cards = <RoundLevelCardState>[];
    final requests = <Future<RoundLevelCardState>>[];
    final resolvedPlayerAddress = playerAddress?.isNotEmpty == true
        ? playerAddress
        : _wallet.isConnected.value
            ? _wallet.currentAddress.value
            : null;
    final progressBySeason = await _loadSeasonProgress(
      playerAddress: resolvedPlayerAddress,
    );

    for (var level = 17; level >= 1; level--) {
      final round = _rounds.roundsByLevel[level];
      requests.add(loadLevel(
        level: level,
        round: round,
        playerAddress: resolvedPlayerAddress,
        seasonProgress:
            round == null ? null : progressBySeason[round.schedule.seasonId],
      ));
      // Public Base RPC endpoints throttle large bursts. Two cards per batch
      // keeps the initial render progressive without flooding the provider.
      if (requests.length == 2 || level == 1) {
        final batch = await Future.wait(requests);
        cards.addAll(batch);
        onBatch?.call(List.unmodifiable(batch));
        requests.clear();
      }
    }
    return cards;
  }

  Future<RoundLevelCardState> loadLevel({
    required int level,
    required GameRoundViewState? round,
    String? playerAddress,
    PlayerSeasonProgress? seasonProgress,
  }) async {
    if (round == null) {
      return RoundLevelCardState(level: level);
    }

    final roundId = BigInt.from(round.schedule.roundId);
    final matrix = await _loadMatrixStats(roundId, round);
    var contractLevelAvailable = true;
    try {
      contractLevelAvailable = await _wallet.isEasyGameLevelAvailable(level);
    } catch (_) {
      // The signed round remains displayable while this optional emergency
      // flag is temporarily unavailable. The contract rechecks it on entry.
    }
    final shouldLoadPlayer = playerAddress?.isNotEmpty == true;

    if (!shouldLoadPlayer) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        seasonProgress: seasonProgress,
        contractLevelAvailable: contractLevelAvailable,
      );
    }

    RoundPlayerState player;
    try {
      player = await _wallet.getRoundPlayerState(
        roundId,
        playerAddress: playerAddress,
      );
    } catch (_) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        seasonProgress: seasonProgress,
        contractLevelAvailable: contractLevelAvailable,
        playerStateResolved: false,
      );
    }

    final eligibility = await _loadEntryEligibility(
      round: round,
      level: level,
      playerAddress: playerAddress!,
      progress: seasonProgress,
    );
    try {
      ArenaSkillStatus? arenaStatus;
      if (player.active) {
        try {
          arenaStatus = await _wallet.getArenaSkillStatus(
            roundId,
            playerAddress: playerAddress,
          );
        } catch (_) {
          // Arena skills may not be configured on an older test deployment.
        }
      }
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        player: player,
        arenaStatus: arenaStatus,
        seasonProgress: seasonProgress,
        entryEligibility: eligibility,
        contractLevelAvailable: contractLevelAvailable,
      );
    } catch (_) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        player: player,
        seasonProgress: seasonProgress,
        entryEligibility: eligibility,
        contractLevelAvailable: contractLevelAvailable,
      );
    }
  }

  Future<RoundLevelCardState> loadPlayerLevel({
    required int level,
    required GameRoundViewState? round,
    String? playerAddress,
  }) async {
    final resolvedPlayerAddress = playerAddress?.isNotEmpty == true
        ? playerAddress
        : _wallet.isConnected.value
            ? _wallet.currentAddress.value
            : null;
    PlayerSeasonProgress? seasonProgress;
    if (round != null && resolvedPlayerAddress?.isNotEmpty == true) {
      final progressBySeason = await _loadSeasonProgress(
        playerAddress: resolvedPlayerAddress,
      );
      seasonProgress = progressBySeason[round.schedule.seasonId];
    }
    return loadLevel(
      level: level,
      round: round,
      playerAddress: resolvedPlayerAddress,
      seasonProgress: seasonProgress,
    );
  }

  Future<RoundMatrixStats> _loadMatrixStats(
    BigInt roundId,
    GameRoundViewState round,
  ) async {
    try {
      return await _wallet.getRoundMatrixStats(roundId);
    } catch (_) {
      final chainState = round.chainState;
      return RoundMatrixStats(
        prizePoolEth: BigInt.zero,
        prizePoolUsdc: BigInt.zero,
        totalWeight: BigInt.zero,
        activeCells: chainState?.occupiedCells ?? BigInt.zero,
        nextCellId: BigInt.zero,
        nextOpenParentId: BigInt.zero,
      );
    }
  }

  Future<Map<int, PlayerSeasonProgress>> _loadSeasonProgress({
    required String? playerAddress,
  }) async {
    if (playerAddress?.isNotEmpty != true) return const {};
    final retryAfter = _progressionRetryAfter;
    if (_progressionQueriesSupported == false &&
        retryAfter != null &&
        DateTime.now().isBefore(retryAfter)) {
      return const {};
    }
    final seasonIds = _rounds.roundsByLevel.values
        .map((round) => round.schedule.seasonId)
        .toSet();
    final result = <int, PlayerSeasonProgress>{};
    for (final seasonId in seasonIds) {
      try {
        result[seasonId] = await _wallet.getPlayerSeasonProgress(
          BigInt.from(seasonId),
          playerAddress: playerAddress,
        );
        _progressionQueriesSupported = true;
        _progressionRetryAfter = null;
      } catch (_) {
        // The currently published Base Sepolia manager predates progression
        // getters. Cache that capability miss instead of reverting 17 calls.
        _progressionQueriesSupported = false;
        _progressionRetryAfter = DateTime.now().add(const Duration(minutes: 2));
        break;
      }
    }
    return result;
  }

  Future<RoundEntryEligibility> _loadEntryEligibility({
    required GameRoundViewState round,
    required int level,
    required String playerAddress,
    required PlayerSeasonProgress? progress,
  }) async {
    if (_progressionQueriesSupported == false || progress == null) {
      return _fallbackEligibility(level: level, progress: progress);
    }
    try {
      return await _wallet.getRoundEntryEligibility(
        seasonId: BigInt.from(round.schedule.seasonId),
        level: level,
        playerAddress: playerAddress,
      );
    } catch (_) {
      return _fallbackEligibility(level: level, progress: progress);
    }
  }

  RoundEntryEligibility _fallbackEligibility({
    required int level,
    required PlayerSeasonProgress? progress,
  }) {
    if (progress == null || !progress.started) {
      return RoundEntryEligibility.eligible;
    }
    if (level <= progress.highestLevel) {
      return RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.alreadyPurchasedOrLower,
        requiredLevel: progress.highestLevel,
        blockingRoundId: BigInt.zero,
      );
    }
    final requiredLevel = progress.nextLevel ?? progress.highestLevel;
    if (level != requiredLevel) {
      return RoundEntryEligibility(
        reason: RoundEntryEligibilityReason.nextLevelRequired,
        requiredLevel: requiredLevel,
        blockingRoundId: BigInt.zero,
      );
    }
    return RoundEntryEligibility.eligible;
  }
}
