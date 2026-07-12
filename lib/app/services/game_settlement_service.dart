import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameSettlementService extends GetxService {
  static const _region = 'us-central1';

  Future<RoundSettlementProofs> fetchProofs(BigInt roundId) async {
    final result = await FirebaseFunctions.instanceFor(region: _region)
        .httpsCallable('getRoundSettlementProofs')
        .call(<String, dynamic>{'roundId': roundId.toString()});
    final data = Map<String, dynamic>.from(result.data as Map);
    final cells = (data['cells'] as List? ?? const [])
        .map((value) => RoundWinningCellProof.fromJson(
              Map<String, dynamic>.from(value as Map),
            ))
        .toList(growable: false);
    return RoundSettlementProofs(
      roundId: BigInt.parse('${data['roundId']}'),
      cells: cells,
    );
  }

  Future<String> settleRound(BigInt roundId) async {
    final proofs = await fetchProofs(roundId);
    return Get.find<WalletConnectService>().settleEasyGameRound(proofs);
  }

  Future<String> claimPrize() =>
      Get.find<WalletConnectService>().claimSettlementPrize();

  Future<SettlementClaimable> getClaimable() =>
      Get.find<WalletConnectService>().getSettlementClaimable();
}
