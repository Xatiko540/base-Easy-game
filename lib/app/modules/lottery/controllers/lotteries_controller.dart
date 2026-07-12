import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';

class LotteriesController extends GetxController {
  final contractLink = Get.find<ContractLinking>();

  setup() async {
    await contractLink.getAbi();
    await contractLink.getCredentials();
    await contractLink.getDeployedContractLotteryGenerator();
  }

  @override
  Future<void> onInit() async {
    await setup();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    contractLink.listenLotteryCreatedEvent().listen((event) async {
      await contractLink.getLotteriesList();
    });
  }
}
