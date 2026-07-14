// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../modules/home/models/levels_models.dart';
import '../modules/home/controllers/profile_controller.dart';
import '../modules/home/views/invite_screen.dart';
import '../modules/home/views/partner_bonus_screen.dart';
import '../modules/home/views/start_page.dart';
import '../modules/home/views/levels.dart';
import '../modules/home/views/profilescreen.dart';
import '../modules/home/views/registrationlevel.dart';
import '../modules/home/views/utility_screens.dart';
import '../services/referral_link_service.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static int _intParam(String name, int fallback) {
    return int.tryParse(Get.parameters[name] ?? '') ?? fallback;
  }

  static double _doubleParam(String name, double fallback) {
    return double.tryParse(Get.parameters[name] ?? '') ?? fallback;
  }

  static String _inviterParam() {
    return ReferralLinkService.inviterFromParams(Get.parameters).isNotEmpty
        ? ReferralLinkService.inviterFromParams(Get.parameters)
        : ReferralLinkService.inviterFromCurrentUrl();
  }

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => ExpressGameScreen(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProfileController>(() => ProfileController());
      }),
    ),
    GetPage(
      name: _Paths.LEVELS,
      page: () => LevelsScreen(
        walletAddress: Get.parameters['wallet']?.trim().isNotEmpty == true
            ? Get.parameters['wallet']!.trim()
            : null,
      ),
    ),
    GetPage(
      name: _Paths.PARTNER_BONUS,
      page: () => PartnerBonusScreen(),
    ),
    GetPage(
      name: _Paths.MATRIX,
      page: () => const MatrixArenaScreen(),
    ),
    GetPage(
      name: _Paths.STATISTICS,
      page: () => const StatisticsScreen(),
    ),
    GetPage(
      name: _Paths.INFORMATION,
      page: () => const InformationScreen(),
    ),
    GetPage(
      name: _Paths.TELEGRAM_BOTS,
      page: () => const TelegramBotsScreen(),
    ),
    GetPage(
      name: _Paths.PROMO,
      page: () => PromoScreen(),
    ),
    GetPage(
      name: _Paths.NOTIFIER_BOT,
      page: () => NotifierBotScreen(),
    ),
    GetPage(
      name: _Paths.SUPPORT,
      page: () => const SupportScreen(),
    ),
    GetPage(
      name: _Paths.REGISTRATION,
      page: () => RegistrationScreen(
        LevelStatus.waiting,
        level: _intParam('level', 1),
        amount: _doubleParam('amount', levelPrice(_intParam('level', 1))),
        inviter: _inviterParam(),
      ),
    ),
    GetPage(
      name: _Paths.ACTIVATE,
      page: () => RegistrationScreen(
        LevelStatus.waiting,
        level: _intParam('level', 1),
        amount: _doubleParam('amount', levelPrice(_intParam('level', 1))),
        inviter: _inviterParam(),
      ),
    ),
    GetPage(
      name: _Paths.INVITE,
      page: () => InviteScreen(inviter: _inviterParam()),
    ),
  ];
}
