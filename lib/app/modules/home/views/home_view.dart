import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:get/get.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/font_styles.dart';
import 'package:lottery_advance/utils/input_decorations.dart';
import 'package:lottery_advance/utils/remove_scroll_glow.dart';
import 'package:lottery_advance/utils/theme.dart';

import 'levels.dart';

class HomeView extends StatelessWidget {
  final contractLink = Get.find<ContractLinking>();
  final avatarSize = 100.0;
  final FocusNode keyFocusNode = FocusNode(); // Управление фокусом

  final WalletConnectService _walletService = Get.find<WalletConnectService>();

  // var contractLink;

  Widget _avatarPreview() {
    return Obx(
      () {
        final controller = Get.find<ContractLinking>();
        return Container(
          height: avatarSize,
          width: avatarSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: controller.svgCode == null
              ? const SizedBox.shrink()
              : Material(
                  elevation: 8,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: SvgPicture.string(
                    controller.svgCode!,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                  ),
                ),
        );
      },
    );
  }

  HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home.connectionViaWallet'.tr,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // backgroundColor: Colors.blue,
        backgroundColor: primaryColor,
        // leading: IconButton(
        //   icon: const Icon(FontAwesomeIcons.github),
        //   onPressed: () async {
        //     const url = 'https://github.com/Xatiko540/base-Easy-game';
        //     await canLaunchUrl(Uri.parse(url))
        //         ? await launchUrl(Uri.parse(url))
        //         : throw 'Could not launch $url';
        //   },
        // ),
        actions: [
          // IconButton(
          //     onPressed: () {
          //       Get.bottomSheet(
          //         Container(
          //           decoration: BoxDecoration(
          //             color: Get.theme.scaffoldBackgroundColor,
          //             borderRadius: const BorderRadius.only(
          //               topLeft: Radius.circular(16),
          //               topRight: Radius.circular(16),
          //             ),
          //           ),
          //           child: Obx(
          //             () => ScrollConfiguration(
          //               behavior: RemoveScrollGlow(),
          //               child: ListView(
          //                 children: [
          //                   ListTile(
          //                     title: Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         const Icon(CupertinoIcons.person)
          //                             .paddingOnly(right: 16),
          //                         const Text(
          //                           'Accounts',
          //                           style: bodySemiBoldBig,
          //                         ),
          //                       ],
          //                     ),
          //                     trailing: Row(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         IconButton(
          //                             onPressed: () {
          //                               Get.changeThemeMode(
          //                                   Get.theme.brightness ==
          //                                           Brightness.dark
          //                                       ? ThemeMode.light
          //                                       : ThemeMode.dark);
          //                               Get.back();
          //                             },
          //                             icon: Icon(Get.theme.brightness ==
          //                                     Brightness.dark
          //                                 ? Icons.light_mode
          //                                 : Icons.dark_mode)),
          //                         IconButton(
          //                             onPressed: Get.back,
          //                             icon: const Icon(CupertinoIcons.clear)),
          //                       ],
          //                     ),
          //                   ),
          //                   if (contractLink.users.isEmpty)
          //                     Column(
          //                       children: [
          //                         FutureBuilder<DrawableRoot?>(
          //                           future: SvgWrapper(accountsSvgCode)
          //                               .generateLogo(),
          //                           builder: (ctx, snapshot) {
          //                             if (!snapshot.hasData) {
          //                               return const SizedBox(
          //                                 width: 50,
          //                                 height: 50,
          //                                 child: CircularProgressIndicator
          //                                     .adaptive(),
          //                               );
          //                             }
          //                             return Row(
          //                               children: [
          //                                 SizedBox(
          //                                   height: avatarSize * 2,
          //                                   width: Get.width,
          //                                   child: CustomPaint(
          //                                     painter: MyPainter(
          //                                         snapshot.data!,
          //                                         Size(
          //                                           Get.width,
          //                                           avatarSize * 2,
          //                                         )),
          //                                     child: Container(),
          //                                   ),
          //                                 ),
          //                               ],
          //                             ).paddingOnly(top: 32);
          //                           },
          //                         ),
          //                         const ListTile(
          //                           title: Text(
          //                             'Your saved Accounts will appear here',
          //                             textAlign: TextAlign.center,
          //                             style: bodySemiBold,
          //                           ),
          //                         ).paddingOnly(top: 8),
          //                       ],
          //                     ),
          //                   ...contractLink.users.map(
          //                     (u) => FutureBuilder<DrawableRoot?>(
          //                         future: SvgWrapper(u.avatar).generateLogo(),
          //                         builder: (ctx, snapshot) {
          //                           if (!snapshot.hasData) {
          //                             return const SizedBox(
          //                               width: 50,
          //                               height: 50,
          //                               child: CircularProgressIndicator
          //                                   .adaptive(),
          //                             );
          //                           }
          //                           return Card(
          //                             shape: RoundedRectangleBorder(
          //                                 borderRadius:
          //                                     BorderRadius.circular(8)),
          //                             elevation: 2,
          //                             child: Dismissible(
          //                               key: UniqueKey(),
          //                               direction: DismissDirection.endToStart,
          //                               onDismissed: (direction) =>
          //                                   contractLink.removeAccount(u),
          //                               background: Container(
          //                                 padding: const EdgeInsets.only(
          //                                     right: 20.0),
          //                                 alignment: Alignment.centerRight,
          //                                 decoration: BoxDecoration(
          //                                     color: Colors.redAccent,
          //                                     borderRadius:
          //                                         BorderRadius.circular(8)),
          //                                 child: const Icon(
          //                                   Icons.delete,
          //                                   size: 32.0,
          //                                   color: Colors.white,
          //                                 ),
          //                               ),
          //                               child: ListTile(
          //                                 onTap: () {
          //                                   contractLink.selectAccount(u);
          //                                   Get.back();
          //                                 },
          //                                 shape: RoundedRectangleBorder(
          //                                     borderRadius:
          //                                         BorderRadius.circular(8)),
          //                                 isThreeLine: true,
          //                                 trailing: const Icon(
          //                                         CupertinoIcons.chevron_forward)
          //                                     .paddingSymmetric(vertical: 16),
          //                                 leading: Container(
          //                                   height: avatarSize / 2,
          //                                   width: avatarSize / 2,
          //                                   decoration: const BoxDecoration(
          //                                     color: Colors.white,
          //                                     shape: BoxShape.circle,
          //                                   ),
          //                                   child: Material(
          //                                     elevation: 8,
          //                                     shape: const CircleBorder(),
          //                                     child: CustomPaint(
          //                                       painter: MyPainter(
          //                                           snapshot.data!,
          //                                           Size(avatarSize / 2,
          //                                               avatarSize / 2)),
          //                                       child: Container(),
          //                                     ),
          //                                   ),
          //                                 ),
          //                                 title: Text(
          //                                   u.name,
          //                                   style: bodySemiBold,
          //                                 ),
          //                                 subtitle: Text(u.address),
          //                               ),
          //                             ),
          //                           ).paddingAll(8);
          //                         }),
          //                   )
          //                 ],
          //               ),
          //             ),
          //           ),
          //         ),
          //       );
          //     },
          //     icon: const Icon(CupertinoIcons.person)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  if (_walletService.isConnected.value) {
                    return Column(
                      children: [
                        Text(
                            'home.walletAddress'.trParams({
                              'address': _walletService.currentAddress.value
                            }),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _walletService.disconnectWallet,
                          child: Text('home.disableWallet'.tr),
                        ),
                      ],
                    );
                  } else {
                    return ElevatedButton(
                      onPressed: () async {
                        try {
                          await _walletService.connectBaseAccount();
                        } catch (e) {
                          Get.snackbar(
                            'common.error'.tr,
                            'home.failedConnectWallet'.tr,
                          );
                        }
                      },
                      child: Text('top.signInBase'.tr),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ScrollConfiguration(
            behavior: RemoveScrollGlow(),
            child: ListView(
              children: [
                if (!kDebugMode)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.creditcard,
                            color: primaryColor,
                            size: 36,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Private key login is disabled',
                            style: bodySemiBoldBig,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'For your safety, Easy Game only uses wallet signing through MetaMask or Base Account. Never paste a private key into any website.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Obx(
                            () => _walletService.isConnected.value
                                ? Text(
                                    _walletService.shortAddress,
                                    style: bodySemiBoldSmall,
                                    textAlign: TextAlign.center,
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await _walletService
                                            .connectBaseAccount();
                                      } catch (e) {
                                        Get.snackbar(
                                          'common.error'.tr,
                                          'home.failedConnectWallet'.tr,
                                        );
                                      }
                                    },
                                    child: Text('top.signInBase'.tr),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ).paddingOnly(top: 16),
                if (kDebugMode) ...[
                  const ListTile(
                    contentPadding: EdgeInsets.all(0),
                    title: Text(
                      'Enter your private key',
                      style: bodySemiBold,
                    ),
                  ).paddingOnly(top: 16),
                  TextField(
                    controller: contractLink.keyController,
                    decoration: borderedInputDecoration(
                      fillColor: primaryColor,
                      hint: 'Copy private key from Metamask and paste here',
                      icon: const Icon(
                        CupertinoIcons.lock_shield,
                        color: primaryColor,
                      ),
                      suffixIcon: IconButton(
                        onPressed: contractLink.keyController.clear,
                        icon: const Icon(
                          CupertinoIcons.clear,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: contractLink.initWallet,
                    splashColor: splashColor,
                    child: Text(
                      'Fetch account details',
                      style: bodySemiBoldSmall.copyWith(color: primaryColor),
                    ),
                  ).paddingSymmetric(vertical: 2),
                  Obx(
                    () => contractLink.isLoading.value &&
                            contractLink.userAddress.value.isEmpty
                        ? const ListTileShimmer(
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.symmetric(vertical: 8),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.userAddress.value.isNotEmpty
                        ? ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            leading: const Icon(
                              CupertinoIcons.person,
                              color: primaryColor,
                            ),
                            title: const Text(
                              'Account Address',
                              style: bodySemiBold,
                            ),
                            subtitle: Text(
                              contractLink.userAddress.value,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.isLoading.value &&
                            contractLink.userBalance.value.isEmpty
                        ? const ListTileShimmer(
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.symmetric(vertical: 8),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.userBalance.value.isNotEmpty
                        ? ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            leading: const Icon(
                              CupertinoIcons.money_dollar_circle,
                              color: primaryColor,
                            ),
                            title: const Text(
                              'Account Balance',
                              style: bodySemiBold,
                            ),
                            subtitle: Text(
                              contractLink.userBalance.value,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.isLoading.value
                        ? const ListTileShimmer(
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.symmetric(vertical: 8),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.userBalance.value.isNotEmpty &&
                            !contractLink.isLoading.value
                        ? const ListTile(
                            contentPadding: EdgeInsets.all(0),
                            title: Text(
                              'Enter Account Name',
                              style: bodySemiBold,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.userBalance.value.isNotEmpty &&
                            !contractLink.isLoading.value
                        ? TextField(
                            controller: contractLink.nameController,
                            decoration: borderedInputDecoration(
                                fillColor: primaryColor,
                                hint: 'Enter name of account to save',
                                icon: const Icon(
                                  CupertinoIcons.person_crop_circle_badge_checkmark,
                                  color: primaryColor,
                                )),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.isLoading.value
                        ? const ProfileShimmer(
                            padding: EdgeInsets.all(0),
                            margin: EdgeInsets.symmetric(vertical: 8),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => contractLink.userAddress.value.isNotEmpty &&
                            contractLink.userBalance.value.isNotEmpty &&
                            !contractLink.isLoading.value
                        ? Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: contractLink.check.value
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.spaceAround,
                              children: [
                                if (!contractLink.check.value)
                                  IconButton(
                                    onPressed: () =>
                                        contractLink.generateSvg(force: true),
                                    icon: const Icon(CupertinoIcons.refresh),
                                  ),
                                GestureDetector(
                                  onTap: contractLink.check.toggle,
                                  child: _avatarPreview(),
                                ),
                                if (!contractLink.check.value)
                                  IconButton(
                                      onPressed: () {
                                        contractLink.check.value = true;
                                      },
                                      icon: const Icon(CupertinoIcons.checkmark)),
                                if (contractLink.check.value)
                                  const SizedBox(
                                    width: 32,
                                  ),
                                if (contractLink.check.value)
                                  Expanded(
                                    child: Column(
                                      children: [
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(0),
                                          title: const Text(
                                            'Address',
                                            style: bodySemiBold,
                                          ),
                                          subtitle: Text(
                                            contractLink.userAddress.value,
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(0),
                                          title: const Text(
                                            'Balance',
                                            style: bodySemiBold,
                                          ),
                                          subtitle: Text(
                                            contractLink.userBalance.value,
                                          ),
                                        ),
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.all(0),
                                          title: const Text(
                                            'Account Name',
                                            style: bodySemiBold,
                                          ),
                                          subtitle: Text(
                                            contractLink.name.value,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                              ],
                            ).paddingAll(16),
                          )
                        : const SizedBox.shrink(),
                  ).paddingOnly(top: 16),
                  Obx(() => (!contractLink.isLoading.value &&
                          contractLink.userAddress.value.isNotEmpty &&
                          !contractLink.isLoading.value)
                      ? MaterialButton(
                          onPressed: contractLink.saveAccount,
                          color: primaryColor,
                          textColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          child: const Text(
                            'Save Account',
                            style: bodySemiBold,
                          ).paddingAll(12),
                        ).paddingSymmetric(vertical: 16, horizontal: 8)
                      : const SizedBox.shrink()),
                  Obx(() => (!contractLink.isLoading.value &&
                          contractLink.userAddress.value.isNotEmpty &&
                          !contractLink.isLoading.value)
                      ? MaterialButton(
                          // onPressed: () => Get.to(() => LotteriesView()),
                          onPressed: () => Get.to(() => LevelsScreen()),
                          color: Colors.green,
                          textColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                          child: const Text(
                            'Proceed to Lottery',
                            style: bodySemiBold,
                          ).paddingAll(12),
                        ).paddingSymmetric(vertical: 4, horizontal: 8)
                      : const SizedBox.shrink()),
                  Obx(
                    () => ListTile(
                      title: Text(
                        contractLink.message.value,
                        style: bodySemiBold,
                      ),
                    ),
                  )
                ],
              ],
            ).paddingSymmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}
