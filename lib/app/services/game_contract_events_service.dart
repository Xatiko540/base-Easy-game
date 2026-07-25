import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_contract_event.dart';

class GameContractEventsService extends GetxService {
  final eventRevision = 0.obs;
  final lastEvent = Rxn<GameContractEvent>();
  final isWatching = false.obs;

  @override
  void onInit() {
    super.onInit();
    isWatching.value = true;
  }

  void notifyEvent(GameContractEvent event) {
    lastEvent.value = event;
    eventRevision.value++;
  }
}
