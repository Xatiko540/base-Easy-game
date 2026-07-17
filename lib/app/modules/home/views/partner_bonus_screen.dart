import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/partner_bonus_controller.dart';
import 'package:lottery_advance/app/modules/home/models/partner_bonus_models.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/widgets/stable_loading_surface.dart';
import 'package:lottery_advance/utils/theme.dart';

part '../widgets/partner_bonus_widgets.dart';
part '../widgets/partner_metric_widgets.dart';
part '../widgets/partner_referral_widgets.dart';
part '../widgets/partner_claim_widgets.dart';
part '../widgets/partner_bonus_table_widgets.dart';

class PartnerBonusScreen extends StatelessWidget {
  const PartnerBonusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return GetX<PartnerBonusController>(
      init: PartnerBonusController(),
      dispose: (_) {
        if (Get.isRegistered<PartnerBonusController>()) {
          Get.delete<PartnerBonusController>();
        }
      },
      builder: (partnerController) {
        final data = partnerController.snapshot.value;
        final loading = partnerController.isLoading.value;
        return ExpressAppShell(
          title: 'nav.partnerBonus'.tr,
          breadcrumb: '${'app.name'.tr} / ${'nav.partnerBonus'.tr}',
          activeSection: 'Partner',
          onRefresh: partnerController.refreshSnapshot,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_3,
                        color: Colors.blueAccent,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'nav.partnerBonus'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Text(
                      walletService.isConnected.value
                          ? 'partner.structure'.trParams({
                              'wallet': walletService.shortAddress,
                            })
                          : 'partner.connectToSee'.tr,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  StableLoadingSurface(
                    isLoading: loading,
                    hasData: data.totalTickets > BigInt.zero ||
                        data.totalWeight > BigInt.zero ||
                        !loading,
                    child: Column(
                      children: [
                        _PartnerMetricGrid(
                          data: data,
                          currency: walletService.nativeSymbol,
                        ),
                        const SizedBox(height: 20),
                        _PersonalReferralPanel(
                          controller: partnerController,
                        ),
                        _ClaimableReferralPanel(controller: partnerController),
                        _ReferralRulesPanel(data: data),
                        const _BonusTable(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
