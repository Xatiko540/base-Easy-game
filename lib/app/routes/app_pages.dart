// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../modules/home/views/ActivateExpressGameScreen.dart';
import '../modules/home/views/InviteScreen.dart';
import '../modules/home/views/PartnerBonusScreen.dart';
import '../modules/home/views/start page.dart';
import '../modules/home/views/levels.dart';
import '../modules/home/views/profilescreen.dart';
import '../modules/home/views/registrationlevel.dart';
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
    ),
    GetPage(
      name: _Paths.LEVELS,
      page: () => LevelsScreen(),
    ),
    GetPage(
      name: _Paths.PARTNER_BONUS,
      page: () => PartnerBonusScreen(),
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
      page: () => ActivateExpressGameScreen(
        level: _intParam('level', 1),
        totalAmount: _doubleParam('amount', levelPrice(_intParam('level', 1))),
        inviter: _inviterParam(),
      ),
    ),
    GetPage(
      name: _Paths.INVITE,
      page: () => InviteScreen(inviter: _inviterParam()),
    ),
  ];
}
