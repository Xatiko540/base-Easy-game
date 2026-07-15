import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class RoundLevelsRepository extends GetxService {
  final WalletConnectService _wallet = Get.find<WalletConnectService>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();

  Future<ContractLevelPrice> loadContractPrice(int level) async {
    final prices = await Future.wait([
      _wallet.getEasyGameLevelPriceWei(level),
      _wallet.getEasyGameLevelPriceUsdc(level),
    ]);
    return ContractLevelPrice(
      ethPriceWei: prices[0],
      usdcPrice: prices[1],
    );
  }

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
    if (round == null) {
      try {
        final values = await Future.wait<dynamic>([
          loadContractPrice(level),
          _wallet.isEasyGameLevelAvailable(level),
        ]);
        final prices = values[0] as ContractLevelPrice;
        return RoundLevelCardState(
          level: level,
          contractEthPriceWei: prices.ethPriceWei,
          contractUsdcPrice: prices.usdcPrice,
          contractLevelAvailable: values[1] as bool,
        );
      } catch (error) {
        return RoundLevelCardState(
          level: level,
          errorMessage: error.toString(),
        );
      }
    }

    final roundId = BigInt.from(round.schedule.roundId);
    late final RoundMatrixStats matrix;
    late final bool contractLevelAvailable;
    try {
      final values = await Future.wait<dynamic>([
        _loadMatrixStats(roundId, round),
        _wallet.isEasyGameLevelAvailable(level),
      ]);
      matrix = values[0] as RoundMatrixStats;
      contractLevelAvailable = values[1] as bool;
    } catch (error) {
      return RoundLevelCardState(
        level: level,
        round: round,
        errorMessage: error.toString(),
      );
    }
    final shouldLoadPlayer =
        playerAddress?.isNotEmpty == true || _wallet.isConnected.value;

    if (!shouldLoadPlayer) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        contractLevelAvailable: contractLevelAvailable,
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
        contractLevelAvailable: contractLevelAvailable,
      );
    } catch (error) {
      return RoundLevelCardState(
        level: level,
        round: round,
        matrix: matrix,
        contractLevelAvailable: contractLevelAvailable,
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
