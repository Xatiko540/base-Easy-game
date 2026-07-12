import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';

class LotteryDetailController extends GetxController {
  final contractLink = Get.find<ContractLinking>();
  final lotteryMaxEntryController = TextEditingController();
  final lotteryETHRequiredController = TextEditingController();
  final RxBool isLoading = true.obs;

  String get lotteryAddress => _lotteryAddress;
  late String _lotteryAddress;

  void init(String address) {
    _lotteryAddress = address;
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      await contractLink.getDeployedContractLottery(_lotteryAddress);
      contractLink.listenPalyerParticipate().listen((event) async {
        await contractLink.reloadContractOnParticipate();
      });
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    lotteryMaxEntryController.dispose();
    lotteryETHRequiredController.dispose();
    super.onClose();
  }
}
