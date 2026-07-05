import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/language_selector.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';

part '../controllers/landing_controller.dart';
part '../models/landing_models.dart';
part '../widgets/landing_widgets.dart';
part '../widgets/landing_topbar_widgets.dart';
part '../widgets/landing_common_widgets.dart';
part '../widgets/landing_hero_widgets.dart';
part '../widgets/landing_feature_widgets.dart';
part '../widgets/landing_preview_widgets.dart';
part '../widgets/landing_floating_widgets.dart';

class ExpressGameScreen extends StatefulWidget {
  const ExpressGameScreen({Key? key}) : super(key: key);

  @override
  State<ExpressGameScreen> createState() => _ExpressGameScreenState();
}

class _ExpressGameScreenState extends State<ExpressGameScreen> {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();
  late final _LandingController _landingController =
      Get.isRegistered<_LandingController>()
          ? Get.find<_LandingController>()
          : Get.put(_LandingController(_walletService));

  @override
  Widget build(BuildContext context) {
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
                        walletService: _walletService,
                        onConnect: _landingController.connectAndEnter,
                      ),
                      const SizedBox(height: 54),
                      _HeroPanel(
                        walletService: _walletService,
                        onConnect: _landingController.connectAndEnter,
                      ),
                      const SizedBox(height: 22),
                      const _StartTimerStrip(),
                      const SizedBox(height: 36),
                      const _FeatureGrid(),
                      const SizedBox(height: 36),
                      _PreviewSearch(
                        controller: _landingController.previewSearchController,
                        onPreview: _landingController.openPreview,
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
  }
}

class WalletScreen extends StatelessWidget {
  const WalletScreen({Key? key}) : super(key: key);

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
  const SettingsScreen({Key? key}) : super(key: key);

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
