import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
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
  final lotteryNameController = TextEditingController();

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
              const FaIcon(
                FontAwesomeIcons.ethereum,
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
                            leading: const FaIcon(
                              FontAwesomeIcons.ticketSimple,
                              color: primaryColor,
                            ),
                            title: Text(
                              contractLink.lottries[index],
                              style: bodySemiBold,
                            ),
                            trailing: const FaIcon(
                              FontAwesomeIcons.circleRight,
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
        child: const Icon(Icons.add),
        onPressed: () {
          Get.defaultDialog(
              title: "Create Lottery",
              titleStyle: bodySemiBold,
              content: Container(
                constraints: BoxConstraints(maxWidth: Get.width * 0.8),
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: lotteryNameController,
                  decoration: borderedInputDecoration(
                    fillColor: primaryColor,
                    hint: 'Diwali lottery',
                    icon: const FaIcon(
                      FontAwesomeIcons.ticketSimple,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: lotteryNameController.clear,
                      icon: const Icon(
                        Icons.clear,
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
                                lotteryNameController.text.trim());
                            lotteryNameController.clear();
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
