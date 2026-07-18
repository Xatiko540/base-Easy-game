import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/language_selector.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/widgets/game_round_presentation.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:lottery_advance/app/modules/home/widgets/neon_honeycomb.dart';

import '../models/levels_models.dart';
import '../controllers/landing_controller.dart';
import '../controllers/wallet_auth_controller.dart';
part '../models/landing_models.dart';
part '../widgets/landing_widgets.dart';
part '../widgets/landing_topbar_widgets.dart';
part '../widgets/landing_common_widgets.dart';
part '../widgets/landing_hero_widgets.dart';
part '../widgets/landing_feature_widgets.dart';
part '../widgets/landing_preview_widgets.dart';
part '../widgets/landing_floating_widgets.dart';

class ExpressGameScreen extends StatelessWidget {
  const ExpressGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LandingController>(
      init: LandingController(),
      dispose: (_) {
        if (Get.isRegistered<LandingController>()) {
          Get.delete<LandingController>();
        }
      },
      builder: (landingController) {
        return Scaffold(
          backgroundColor: EasyGameTheme.page,
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: EasyGameTheme.page,
                    gradient: EasyGameTheme.shellGlow,
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 22, 28, 44),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LandingTopBar(
                            onConnect: landingController.connectAndEnter,
                          ),
                          const SizedBox(height: 54),
                          _HeroPanel(
                            onConnect: landingController.connectAndEnter,
                          ),
                          const SizedBox(height: 22),
                          const _StartTimerStrip(),
                          const SizedBox(height: 36),
                          const _FeatureGrid(),
                          const SizedBox(height: 36),
                          _PreviewSearch(
                            onChanged: (value) =>
                                landingController.previewQuery.value = value,
                            onPreview: landingController.openPreview,
                          ),
                          const SizedBox(height: 30),
                          const _SchedulePreview(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const _LandingFloatingButtons(),
            ],
          ),
        );
      },
    );
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'utility.wallet'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'common.settings'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
