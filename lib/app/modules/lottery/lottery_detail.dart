import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/lottery/controllers/lottery_detail_controller.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';
import 'package:lottery_advance/utils/constants.dart';
import 'package:lottery_advance/utils/font_styles.dart';
import 'package:lottery_advance/utils/input_decorations.dart';
import 'package:lottery_advance/utils/remove_scroll_glow.dart';
import 'package:lottery_advance/utils/theme.dart';

class LotteryDetail extends StatelessWidget {
  final String lotteryAddress;
  const LotteryDetail({Key? key, required this.lotteryAddress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<LotteryDetailController>(
      init: LotteryDetailController()..init(lotteryAddress),
      dispose: (_) => Get.delete<LotteryDetailController>(),
      builder: (_) => Container(
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      height: Get.height * 0.88,
      child: ScrollConfiguration(
        behavior: RemoveScrollGlow(),
        child: Obx(() => Get.find<LotteryDetailController>().isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Obx(
                () => ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: Get.width * 0.4,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Get.theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(16),
                            ),
                          ),
                        ).marginOnly(top: 5),
                      ],
                    ),
                    Obx(
                      () => SizedBox(
                        width: Get.width * 0.8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: Get.back,
                              icon: const Icon(Icons.arrow_back),
                            ),
                            (Get.find<ContractLinking>().managerAddress.value ==
                                        Get.find<ContractLinking>().userAddress.value &&
                                    Get.find<ContractLinking>().lotteryLive.value == false)
                                ? PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text(
                                          "Delete Lottery",
                                          style: bodySemiLight,
                                        ),
                                        onTap: () async {
                                          Get.back();
                                          await Get.find<ContractLinking>().deleteLotteryFunc(
                                              lotteryAddress);
                                        },
                                      )
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        Get.find<ContractLinking>().lotryname.value,
                        style: headingStyleSemiBold,
                      ),
                    ),
                    const Center(
                      child: Text(
                        "by",
                        style: bodySemiLightSmall,
                      ),
                    ).marginSymmetric(vertical: 5),
                    Center(
                      child: Text(
                        Get.find<ContractLinking>().managerAddress.value,
                        style: bodySemiBoldSmall,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.award,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              Get.find<ContractLinking>().contractBalance.value,
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.groups,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              '${Get.find<ContractLinking>().players.length}',
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            FaIcon(
                              Get.find<ContractLinking>().lotteryLive.value
                                  ? FontAwesomeIcons.toggleOn
                                  : FontAwesomeIcons.toggleOff,
                              color: primaryColor,
                              size: 22,
                            ).marginOnly(bottom: 5),
                            Text(
                              Get.find<ContractLinking>().lotteryLive.value
                                  ? "Active"
                                  : "Inactive",
                              style: bodySemiBold,
                            ),
                          ],
                        ),
                      ],
                    ).marginSymmetric(vertical: 20),
                    ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.gift,
                        color: primaryColor,
                      ),
                      title: const Text(
                        'Last Winner',
                        style: bodySemiBold,
                      ),
                      subtitle: Obx(
                        () => Text(
                          '${Get.find<ContractLinking>().lastWinner.value.isEmpty ? defaultHex : Get.find<ContractLinking>().lastWinner.value} ',
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const FaIcon(
                        FontAwesomeIcons.ticketSimple,
                        color: primaryColor,
                      ),
                      title: Text(
                        'Tickets Buy ( Max : ${Get.find<ContractLinking>().lotteryLimit.value} )',
                        style: bodySemiBold,
                      ),
                      subtitle: Obx(
                        () => Text(
                          '${Get.find<ContractLinking>().lotteryBuyCount.value}',
                        ),
                      ),
                    ),
                    if (Get.find<ContractLinking>().managerAddress.value ==
                        Get.find<ContractLinking>().userAddress.value)
                      ListTile(
                        leading: const FaIcon(
                          FontAwesomeIcons.clipboardCheck,
                          color: primaryColor,
                        ),
                        title: const Text(
                          'Tickets Sold',
                          style: bodySemiBold,
                        ),
                        subtitle: Obx(
                          () => Text(
                            '${Get.find<ContractLinking>().lotterySold.value}',
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () => Get.find<ContractLinking>().isLoadingParticipate.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        Get.find<ContractLinking>().animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : Get.find<ContractLinking>().lotteryLive.value
                                  ? Get.find<ContractLinking>().lotteryBuyCount.value == 0
                                      ? MaterialButton(
                                          onPressed:
                                              Get.find<ContractLinking>().participateInLottery,
                                          color: primaryColor,
                                          textColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(32)),
                                          child: Text(
                                            '${Get.find<ContractLinking>().lotteryETH} ETH \n Participate',
                                            style: bodySemiBold,
                                            textAlign: TextAlign.center,
                                          ).paddingAll(12),
                                        ).paddingSymmetric(
                                          vertical: 4, horizontal: 16)
                                      : (Get.find<ContractLinking>().players.contains(
                                                  Get.find<ContractLinking>()
                                                      .userAddress.value) &&
                                              Get.find<ContractLinking>()
                                                      .lotteryBuyCount.value <
                                                  Get.find<ContractLinking>()
                                                      .lotteryLimit.value)
                                          ? MaterialButton(
                                              onPressed:
                                                  Get.find<ContractLinking>().participateInLottery,
                                              color: primaryColor,
                                              textColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          32)),
                                              child: Text(
                                                '${Get.find<ContractLinking>().lotteryETH} ETH \n Buy more',
                                                style: bodySemiBold,
                                                textAlign: TextAlign.center,
                                              ).paddingAll(12),
                                            ).paddingSymmetric(
                                              vertical: 4, horizontal: 16)
                                          : Text(
                                              "All tickets sold",
                                              style: bodySemiBold.copyWith(
                                                  color: Colors.red),
                                            )
                                  : const SizedBox.shrink(),
                        ),
                        Obx(
                          () => Get.find<ContractLinking>().isLoadingDeclareWinner.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        Get.find<ContractLinking>().animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : (Get.find<ContractLinking>().userAddress.value ==
                                          Get.find<ContractLinking>().managerAddress.value &&
                                      Get.find<ContractLinking>().lotteryLive.value)
                                  ? MaterialButton(
                                      onPressed: Get.find<ContractLinking>().pickWinner,
                                      color: secondaryColor,
                                      textColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32)),
                                      child: const Text(
                                        'Pick Winner',
                                        style: bodySemiBold,
                                      ).paddingAll(12),
                                    ).paddingSymmetric(
                                      vertical: 16, horizontal: 16)
                                  : Container(),
                        ),
                        Obx(
                          () => Get.find<ContractLinking>().isLoadingActivateLottery.value
                              ? Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor:
                                        Get.find<ContractLinking>().animationController.drive(
                                      ColorTween(
                                        begin: primaryColor,
                                        end: Colors.green,
                                      ),
                                    ),
                                  ),
                                )
                              : (Get.find<ContractLinking>().lotteryLive.value == false &&
                                      Get.find<ContractLinking>().managerAddress.value ==
                                          Get.find<ContractLinking>().userAddress.value)
                                  ? MaterialButton(
                                      onPressed: () {
                                        activateLotteryDialog();
                                      },
                                      color: primaryColor,
                                      textColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(32)),
                                      child: const Text(
                                        'Activate Lottery',
                                        style: bodySemiBold,
                                        textAlign: TextAlign.center,
                                      ).paddingAll(12),
                                    ).paddingSymmetric(
                                      vertical: 4, horizontal: 16)
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    ListTile(
                      title: Obx(
                        () => Text(
                          "${Get.find<ContractLinking>().message.value}",
                          textAlign: TextAlign.center,
                          style: bodySemiBold.copyWith(
                              color: Get.find<ContractLinking>().message.contains('error')
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      ),
      ));
  }

  void activateLotteryDialog() {
    final controller = Get.find<LotteryDetailController>();
    Get.back();
    Get.defaultDialog(
        title: "Activate Lottery",
        titleStyle: bodySemiBold,
        content: Container(
          constraints: BoxConstraints(maxWidth: Get.width * 0.8),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: controller.lotteryMaxEntryController,
                decoration: borderedInputDecoration(
                  fillColor: primaryColor,
                  hint: 'Ex: 10',
                  icon: const Icon(
                    Icons.groups,
                    color: primaryColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.lotteryMaxEntryController.clear,
                    icon: const Icon(
                      Icons.clear,
                      color: primaryColor,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ).marginOnly(bottom: 10),
              TextField(
                controller: controller.lotteryETHRequiredController,
                decoration: borderedInputDecoration(
                  fillColor: primaryColor,
                  hint: 'Ex: 1',
                  icon: const FaIcon(
                    FontAwesomeIcons.ethereum,
                    color: primaryColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.lotteryETHRequiredController.clear,
                    icon: const Icon(
                      Icons.clear,
                      color: primaryColor,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          Obx(
            () => Get.find<ContractLinking>().isLoadingActivateLottery.value
                ? const Center(child: CircularProgressIndicator())
                : MaterialButton(
                    onPressed: () async {
                      await Get.find<ContractLinking>().activateLotteryFunc(
                        int.parse(controller.lotteryMaxEntryController.text.trim()),
                        int.parse(controller.lotteryETHRequiredController.text.trim()),
                      );
                      controller.lotteryMaxEntryController.clear();
                      controller.lotteryETHRequiredController.clear();
                      Get.back();
                    },
                    splashColor: splashColor,
                    child: Text(
                      'Activate',
                      style: bodySemiBoldSmall.copyWith(color: primaryColor),
                    ),
                  ).paddingSymmetric(vertical: 2),
          ),
        ]);
  }
}
