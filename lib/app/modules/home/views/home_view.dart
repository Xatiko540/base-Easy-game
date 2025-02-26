import 'package:flutter/material.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_web3/ethereum.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/lottery/lotteries_view.dart';
import 'package:lottery_advance/app/modules/home/views/my_paint.dart';
import 'package:lottery_advance/app/modules/home/views/svg_wrapper.dart';
import 'package:lottery_advance/app/services/contract_linking.dart';
import 'package:lottery_advance/utils/constants.dart';
import 'package:lottery_advance/utils/font_styles.dart';
import 'package:lottery_advance/utils/input_decorations.dart';
import 'package:lottery_advance/utils/remove_scroll_glow.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import 'levels.dart';

class HomeView extends StatelessWidget {
  final contractLink = Get.put(ContractLinking(), permanent: true);
  final avatarSize = 100.0;
  final FocusNode keyFocusNode = FocusNode(); // Управление фокусом

  final WalletConnectService _walletService = WalletConnectService();

  // var contractLink;

  Widget _avatarPreview() {
    return GetBuilder<ContractLinking>(
      builder: (_) => Container(
        height: avatarSize,
        width: avatarSize,
        child: _.svgRoot == null
            ? const SizedBox.shrink()
            : Material(
                elevation: 8,
                shape: const CircleBorder(),
                child: CustomPaint(
                  painter: MyPainter(_.svgRoot!, Size(avatarSize, avatarSize)),
                  child: Container(),
                ),
              ),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  HomeView({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection via Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          //                         const Icon(FontAwesomeIcons.user)
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
          //                             icon: const Icon(Icons.clear)),
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
          //                                         Icons.arrow_forward_ios)
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
          //     icon: const Icon(FontAwesomeIcons.user)),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  if (_walletService.isConnected) {
                    return Column(
                      children: [
                        Text('Wallet address: ${_walletService.currentAddress}', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _walletService.disconnectWallet,
                          child: const Text('Disable wallet'),
                        ),
                      ],
                    );
                  } else {
                    return ElevatedButton(
                      onPressed: () async {
                        try {
                          await _walletService.connectWallet();
                        } catch (e) {
                          Get.snackbar('Error', 'Failed to connect wallet');
                        }
                      },
                      child: const Text('Connect wallet'),
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
                      FontAwesomeIcons.userLock,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      onPressed: contractLink.keyController.clear,
                      icon: const Icon(
                        Icons.clear,
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
                            FontAwesomeIcons.userAlt,
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
                            FontAwesomeIcons.ethereum,
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
                                FontAwesomeIcons.userAstronaut,
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
                                  icon: const Icon(Icons.refresh),
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
                                    icon: const Icon(Icons.check)),
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
                ListTile(
                  title: Text(
                    contractLink.message.value,
                    style: bodySemiBold,
                  ),
                )
              ],
            ).paddingSymmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }
}


class WalletConnectService extends GetxController {
  final RxString _currentAddress = ''.obs;
  final RxBool _isConnected = false.obs;

  // Доступ к данным
  String get currentAddress => _currentAddress.value;
  bool get isConnected => _isConnected.value;

  // Проверка наличия кошелька
  bool get isWalletAvailable => ethereum != null;

  // Подключение кошелька
  Future<void> connectWallet() async {
    if (isWalletAvailable) {
      try {
        final accounts = await ethereum!.requestAccount();
        _currentAddress.value = accounts.first;
        _isConnected.value = true;
        print('Wallet connected: ${_currentAddress.value}');
      } catch (e) {
        _isConnected.value = false;
        print('Connection error: $e');
        rethrow;
      }
    } else {
      print('MetaMask or other Web3 wallet is not installed');
      throw Exception('Wallet not available');
    }
  }

  // Отключение кошелька
  void disconnectWallet() {
    _currentAddress.value = '';
    _isConnected.value = false;
    print('Wallet is disabled');
  }
}

