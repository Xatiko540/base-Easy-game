import 'package:get/get.dart';
import '../controllers/lotteries_controller.dart';

class LotteryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LotteriesController>(() => LotteriesController(), fenix: true);
  }
}
