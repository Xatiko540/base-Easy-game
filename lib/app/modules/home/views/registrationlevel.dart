import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/ActivateExpressGameScreen.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';

import '../models/levels_models.dart';

part '../controllers/registration_controller.dart';
part '../models/registration_models.dart';
part '../widgets/registration_widgets.dart';
part '../widgets/registration_asset_widgets.dart';
part '../widgets/registration_levels_widgets.dart';
part '../widgets/registration_common_widgets.dart';
part '../widgets/registration_summary_widgets.dart';

class RegistrationScreen extends StatelessWidget {
  final int level;
  final double amount;
  final String? inviter;

  RegistrationScreen(
    LevelStatus level1, {
    Key? key,
    this.level = 3,
    this.amount = 0.1,
    String? inviter,
  })  : inviter = inviter ?? WalletConnectService.easyGameInviter,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = '$level-${inviter ?? 'default'}';
    return GetX<_RegistrationController>(
      init: _RegistrationController()
        ..configure(level: level, amount: amount, inviter: inviter),
      tag: tag,
      dispose: (_) {
        if (Get.isRegistered<_RegistrationController>(tag: tag)) {
          Get.delete<_RegistrationController>(tag: tag);
        }
      },
      builder: (registrationController) {
        final walletService = Get.find<WalletConnectService>();
        final currency = registrationController.currencySymbol;
        final selectedLevel = registrationController.selectedLevel.value;
        final selectedAmount = registrationController.selectedAmount.value;
        final paymentAsset = registrationController.paymentAsset.value;
        final networkChecked = registrationController.networkChecked.value;
        final balanceChecked = registrationController.balanceChecked.value;
        final balanceMessage = registrationController.balanceMessage.value;

        return ExpressAppShell(
          title: 'registration.title'.tr.replaceAll('\n', ' '),
          breadcrumb:
              '${'app.name'.tr} / ${'registration.title'.tr.split('\n').first}',
          balanceLabel: '${selectedAmount.toStringAsFixed(3)} $currency',
          activeSection: 'Dashboard',
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: EasyGameTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'registration.title'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'registration.subtitle'
                                .trParams({'currency': currency}),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _PaymentAssetSelector(
                            selected: paymentAsset,
                            nativeSymbol: walletService.nativeSymbol,
                            onChanged:
                                registrationController.selectPaymentAsset,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'registration.uplineAddress'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            registrationController.uplineLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DarkInput(
                                  child: TextField(
                                    controller:
                                        registrationController.uplineController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '314274 or 0x...',
                                      hintStyle:
                                          TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed:
                                      registrationController.approveUpline,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3A3B3C),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'registration.approveUpline'.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'registration.chooseLevel'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _DarkInput(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF242526),
                                value: selectedLevel,
                                iconEnabledColor: Colors.white,
                                items: [
                                  for (var i = easyGameLevelCount; i >= 1; i--)
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text(
                                        'Level $i (${levelPrice(i).toStringAsFixed(3)} $currency)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  registrationController.selectLevel(value);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _CheckPill(
                                  icon: Icons.hub,
                                  label: networkChecked
                                      ? 'registration.networkOk'.tr
                                      : 'registration.networkCheck'.tr,
                                  active: networkChecked,
                                  onPressed:
                                      registrationController.checkNetwork,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _CheckPill(
                                  icon: Icons.monetization_on,
                                  label: balanceChecked
                                      ? 'registration.balanceOk'.tr
                                      : balanceMessage.isEmpty
                                          ? 'registration.balanceCheck'.tr
                                          : 'registration.balanceLow'.tr,
                                  active: balanceChecked,
                                  onPressed:
                                      registrationController.checkBalance,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _PaymentSummary(
                            amount: selectedAmount,
                            currencySymbol: currency,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: registrationController.continueToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: EasyGameTheme.actionGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  '${'registration.activate'.tr} (${selectedAmount.toStringAsFixed(3)} $currency)',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _ActiveGamesStrip(
                      selectedLevel: selectedLevel,
                      currencySymbol: currency,
                      onPickLevel: registrationController.selectLevel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
