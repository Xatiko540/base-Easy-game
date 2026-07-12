import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/app_config_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/notifications_service.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/firebase_data_service.dart';
import 'package:lottery_advance/app/services/language_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/game_clock_service.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/repositories/game_user_repository.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/translations/app_translations.dart';
import 'package:lottery_advance/core/binary_matrix.dart';
import 'package:lottery_advance/utils/theme.dart';

import 'app/routes/app_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  print("[DEBUG] main: Starting application...");
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print("[DEBUG] main: WidgetsFlutterBinding initialized.");

    await GetStorage.init();
    print("[DEBUG] main: GetStorage initialized.");

    print("[DEBUG] main: Initializing BinaryMatrix...");
    final matrix = BinaryMatrix();
    matrix.fillMatrix(6); // Заполняем 6 уровней
    print("[DEBUG] main: BinaryMatrix filled.");
    matrix.printMatrix();
    print("[DEBUG] main: BinaryMatrix printed.");

    print("[DEBUG] main: Registering WalletConnectService...");
    Get.lazyPut<WalletConnectService>(() => WalletConnectService(),
        fenix: true);
    print("[DEBUG] main: WalletConnectService lazyPut completed.");

    final languageService = Get.put(LanguageService(), permanent: true);
    languageService.load();

    Get.put(AppConfigService(), permanent: true);
    Get.put(NotificationsService(), permanent: true);
    Get.put(FirebaseBackendService(), permanent: true);
    Get.put(FirebaseDataService(), permanent: true);
    Get.put(GameClockService(), permanent: true);
    Get.put(GameScheduleService(), permanent: true);
    Get.put(GameRoundBlockchainService().bind(), permanent: true);
    Get.put(GameSettlementService(), permanent: true);
    Get.put(GameRoundsRepository().bind(), permanent: true);
    Get.put(GameRoundsController(), permanent: true);
    Get.put(GameUserRepository().bind(), permanent: true);
    print(kIsWeb
        ? "[DEBUG] main: Web services registered."
        : "[DEBUG] main: Mobile services registered.");

    print("[DEBUG] main: Running runApp...");
    runApp(
      GetMaterialApp(
        title: "Easy Games",
        initialRoute: ReferralLinkService.isReferralEntryUri(Uri.base)
            ? Routes.INVITE
            : AppPages.INITIAL,
        getPages: AppPages.routes,
        translations: AppTranslations(),
        locale: languageService.locale,
        fallbackLocale: const Locale('en'),
        defaultTransition: Transition.fadeIn,
        theme: lightTheme,
        darkTheme: darkTheme,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
      ),
    );
    print("[DEBUG] main: runApp executed.");

    print("[DEBUG] main: Initializing background services...");
    _initializeBackgroundServices();
  } catch (e, stacktrace) {
    print("[DEBUG] main: FATAL ERROR during initialization: $e");
    print("[DEBUG] main: Stacktrace: $stacktrace");
  }
}

Future<void> _initializeBackgroundServices() async {
  try {
    await Get.find<AppConfigService>().fetch();
  } catch (e, st) {
    debugPrint('AppConfigService init failed: $e\n$st');
  }

  try {
    await Get.find<GameClockService>().init();
  } catch (e, st) {
    debugPrint('GameClockService init failed: $e\n$st');
  }

  try {
    await Get.find<GameScheduleService>().init();
  } catch (e, st) {
    debugPrint('GameScheduleService init failed: $e\n$st');
  }

  try {
    await Get.find<NotificationsService>().init();
  } catch (e, st) {
    debugPrint('NotificationsService init failed: $e\n$st');
  }

  try {
    await Get.find<FirebaseBackendService>().init();
  } catch (e, st) {
    debugPrint('FirebaseBackendService init failed: $e\n$st');
  }
}
