import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/lottery/controllers/lotteries_controller.dart';
import 'package:lottery_advance/app/modules/lottery/lottery_detail.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';
import 'package:lottery_advance/utils/font_styles.dart';
import 'package:lottery_advance/utils/input_decorations.dart';
import 'package:lottery_advance/utils/remove_scroll_glow.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:lottery_advance/utils/constants.dart';

class LotteriesView extends StatelessWidget {
  LotteriesView({Key? key}) : super(key: key);
  final contractLink = Get.find<ContractLinking>();
  final controller = Get.find<LotteriesController>();

  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context)
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Lotteries',
          style: bodySemiBoldBig,
        ),
        actions: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.money_dollar_circle,
                color: Colors.white,
                size: 22,
              ).marginOnly(right: 5),
              Obx(
                () => Text(
                  contractLink.userBalance.value,
                  style: bodySemiBoldSmall,
                ).marginOnly(right: 10),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: RefreshIndicator(
            onRefresh: contractLink.reloadContract,
            child: ScrollConfiguration(
              behavior: RemoveScrollGlow(),
              child: Obx(
                () => contractLink.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: contractLink.lottries.length,
                        itemBuilder: ((context, index) {
                          if (contractLink.lottries[index] == defaultHex) {
                            return const SizedBox.shrink();
                          }
                          return ListTile(
                            key: UniqueKey(),
                            leading: const Icon(
                              CupertinoIcons.ticket,
                              color: primaryColor,
                            ),
                            title: Text(
                              contractLink.lottries[index],
                              style: bodySemiBold,
                            ),
                            trailing: const Icon(
                              CupertinoIcons.chevron_right_circle,
                              color: primaryColor,
                            ),
                            onTap: () async {
                              lotteryDetail(
                                  contractLink.lottries[index], context);
                            },
                          ).paddingAll(8.0).marginSymmetric(vertical: 10);
                        }),
                      ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(CupertinoIcons.add),
        onPressed: () {
          Get.defaultDialog(
              title: "Create Lottery",
              titleStyle: bodySemiBold,
              content: Container(
                constraints: BoxConstraints(maxWidth: Get.width * 0.8),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controller.lotteryNameController,
                  decoration: borderedInputDecoration(
                    fillColor: primaryColor,
                    hint: 'Diwali lottery',
                    icon: const Icon(
                      CupertinoIcons.ticket,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: controller.lotteryNameController.clear,
                      icon: const Icon(
                        CupertinoIcons.clear,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Obx(
                  () => contractLink.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : MaterialButton(
                          onPressed: () async {
                            await contractLink.createLotteryFunc(
                                controller.lotteryNameController.text.trim());
                            controller.lotteryNameController.clear();
                            Get.back();
                          },
                          splashColor: splashColor,
                          child: Text(
                            'Create',
                            style:
                                bodySemiBoldSmall.copyWith(color: primaryColor),
                          ),
                        ).paddingSymmetric(vertical: 2),
                ),
              ]);
        },
      ),
    );
  }

  void lotteryDetail(String address, BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return LotteryDetail(lotteryAddress: address);
      },
    );
  }
}
