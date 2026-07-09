import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';

part '../models/partner_bonus_models.dart';
part '../controllers/partner_bonus_controller.dart';
part '../widgets/partner_bonus_widgets.dart';
part '../widgets/partner_metric_widgets.dart';
part '../widgets/partner_referral_widgets.dart';
part '../widgets/partner_claim_widgets.dart';
part '../widgets/partner_bonus_table_widgets.dart';

class PartnerBonusScreen extends StatelessWidget {
  PartnerBonusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return GetX<_PartnerBonusController>(
      init: _PartnerBonusController(),
      dispose: (_) => Get.delete<_PartnerBonusController>(),
      builder: (_partnerController) {
        return Obx(
          () {
            final data = _partnerController.snapshot.value;
            return ExpressAppShell(
              title: 'nav.partnerBonus'.tr,
              breadcrumb: '${'app.name'.tr} / ${'nav.partnerBonus'.tr}',
              activeSection: 'Partner',
              onRefresh: _partnerController.refreshSnapshot,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 18),
                      if (_partnerController.isLoading.value)
                        const LinearProgressIndicator(
                          color: EasyGameTheme.teal,
                          backgroundColor: EasyGameTheme.border,
                        ),
                      if (_partnerController.isLoading.value)
                        const SizedBox(height: 14),
                      _PartnerMetricGrid(
                        data: data,
                        currency: walletService.nativeSymbol,
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 860;
                          final left = Column(
                            children: [
                              _PersonalReferralPanel(
                                controller: _partnerController,
                              ),
                              const SizedBox(height: 22),
                              _ClaimableReferralPanel(
                                controller: _partnerController,
                              ),
                              const SizedBox(height: 22),
                              const _BonusTable(),
                            ],
                          );
                          final right = Column(
                            children: [
                              _ReferralRulesPanel(data: data),
                              const SizedBox(height: 22),
                              const _ReferralFlowPanel(),
                            ],
                          );
                          if (compact) {
                            return Column(children: [left, right]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: left),
                              const SizedBox(width: 22),
                              Expanded(flex: 6, child: right),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
      },
    );
      },
    );
  }
}
