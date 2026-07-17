import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/controllers/profile_controller.dart';
import 'package:lottery_advance/app/modules/home/models/profile_models.dart';
import 'package:lottery_advance/app/modules/home/models/profile_session_model.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/widgets/stable_loading_surface.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/levels_models.dart';

part '../widgets/profile_widgets.dart';
part '../widgets/profile_common_widgets.dart';
part '../widgets/profile_header_widgets.dart';
part '../widgets/profile_program_widgets.dart';
part '../widgets/profile_about_widgets.dart';
part '../widgets/profile_activity_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<ProfileController>(
      builder: (profileController) {
        final data = profileController.dashboard.value;
        final loading = profileController.isLoading.value;
        final error = profileController.errorMessage.value;
        final transactionsError = profileController.transactionsError.value;
        final isClaimingPrize = profileController.isClaimingPrize.value;
        final isClaimingReferral = profileController.isClaimingReferral.value;
        return ExpressAppShell(
          title: 'nav.dashboard'.tr,
          breadcrumb: '${'app.name'.tr} / ${'nav.dashboard'.tr}',
          activeSection: 'Dashboard',
          onRefresh: profileController.refreshDashboard,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(
                    profileId: profileController.profileId,
                    data: data,
                    referralLink: profileController.referralLink,
                    onCopy: profileController.copyReferralLink,
                    onShare: profileController.shareReferralLink,
                  ),
                  const SizedBox(height: 26),
                  if (error.isNotEmpty) ...[
                    _ProfileErrorBanner(
                      message: error,
                      onRefresh: profileController.refreshDashboard,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _ProfileSectionHeading(
                    title: 'profile.smartGames'.tr,
                    subtitle: 'profile.smartGamesSubtitle'.tr,
                  ),
                  const SizedBox(height: 16),
                  StableLoadingSurface(
                    isLoading: loading,
                    hasData: data.levels.isNotEmpty || data.player != null,
                    child: Column(
                      children: [
                        _ProgramPanel(data: data),
                        const SizedBox(height: 22),
                        _AboutContractsRow(
                          controller: profileController,
                          data: data,
                          isClaimingPrize: isClaimingPrize,
                          isClaimingReferral: isClaimingReferral,
                        ),
                        const SizedBox(height: 22),
                        _RecentActivityTable(
                          data: data,
                          errorMessage: transactionsError,
                          onRefresh: profileController.refreshDashboard,
                        ),
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
