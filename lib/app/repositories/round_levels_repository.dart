import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class RoundLevelsRepository extends GetxService {
  final WalletConnectService _wallet = Get.find<WalletConnectService>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();

  Future<List<RoundLevelCardState>> loadCards({String? playerAddress}) async {
    final cards = <RoundLevelCardState>[];
    final requests = <Future<RoundLevelCardState>>[];

    for (var level = 17; level >= 1; level--) {
      requests.add(loadLevel(
        level: level,
        round: _rounds.roundsByLevel[level],
        playerAddress: playerAddress,
      ));
      if (requests.length == 6 || level == 1) {
        cards.addAll(await Future.wait(requests));
        requests.clear();
      }
    }
    return cards;
  }

  Future<RoundLevelCardState> loadLevel({
    required int level,
    required GameRoundViewState? round,
    String? playerAddress,
  }) async {
    if (round == null) return RoundLevelCardState(level: level);

    final roundId = BigInt.from(round.schedule.roundId);
    final matrix = await _loadMatrixStats(roundId, round);
    final shouldLoadPlayer =
        playerAddress?.isNotEmpty == true || _wallet.isConnected.value;

    if (!shouldLoadPlayer) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
      );
    }

    try {
      final player = await _wallet.getRoundPlayerState(
        roundId,
        playerAddress: playerAddress,
      );
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        player: player,
      );
    } catch (error) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        errorMessage: error.toString(),
      );
    }
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
        prizePoolEth: chainState?.prizePoolEth ?? BigInt.zero,
        prizePoolUsdc: chainState?.prizePoolUsdc ?? BigInt.zero,
        totalWeight: BigInt.zero,
        activeCells: chainState?.occupiedCells ?? BigInt.zero,
        nextCellId: BigInt.zero,
        nextOpenParentId: BigInt.zero,
      );
    }
  }
}
