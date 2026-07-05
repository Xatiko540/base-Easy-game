import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/modules/home/views/partner_bonus_screen.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';

part '../models/profile_models.dart';
part '../controllers/profile_controller.dart';
part '../widgets/profile_widgets.dart';
part '../widgets/profile_common_widgets.dart';
part '../widgets/profile_header_widgets.dart';
part '../widgets/profile_program_widgets.dart';
part '../widgets/profile_about_widgets.dart';
part '../widgets/profile_activity_widgets.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  late final _ProfileController _profileController =
      Get.isRegistered<_ProfileController>()
          ? Get.find<_ProfileController>()
          : Get.put(_ProfileController(Get.find<WalletConnectService>()));

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final data = _profileController.dashboard.value;
        final loading = _profileController.isLoading.value;
        return ExpressAppShell(
          title: 'nav.dashboard'.tr,
          breadcrumb: '${'app.name'.tr} / ${'nav.dashboard'.tr}',
          activeSection: 'Dashboard',
          onRefresh: _profileController.refreshDashboard,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    walletService: walletService,
                    profileId: _profileController.profileId,
                    data: data,
                    referralLink: _profileController.referralLink,
                    onCopy: _profileController.copyReferralLink,
                    onShare: _profileController.shareReferralLink,
                  ),
                  const SizedBox(height: 26),
                  if (loading)
                    const LinearProgressIndicator(
                      color: EasyGameTheme.teal,
                      backgroundColor: EasyGameTheme.border,
                    ),
                  if (loading) const SizedBox(height: 14),
                  _ProfileSectionHeading(
                    title: 'profile.smartGames'.tr,
                    subtitle: 'profile.smartGamesSubtitle'.tr,
                  ),
                  const SizedBox(height: 16),
                  _ProgramPanel(
                    walletService: walletService,
                    data: data,
                  ),
                  const SizedBox(height: 22),
                  _AboutContractsRow(
                    walletService: walletService,
                    controller: _profileController,
                    data: data,
                  ),
                  const SizedBox(height: 22),
                  _RecentActivityTable(
                    walletService: walletService,
                    data: data,
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
