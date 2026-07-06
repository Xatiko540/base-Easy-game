import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/notifications_service.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/language_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/translations/app_translations.dart';
import 'package:lottery_advance/utils/theme.dart';

import 'app/modules/controller/lotteries_controller.dart';
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

    final notifications = NotificationsService();
    Get.put(notifications, permanent: true);
    final firebaseBackend = FirebaseBackendService(
      walletService: Get.find<WalletConnectService>(),
      notifications: notifications,
    );
    Get.put(firebaseBackend, permanent: true);
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
    _initializeBackgroundServices(notifications, firebaseBackend);
  } catch (e, stacktrace) {
    print("[DEBUG] main: FATAL ERROR during initialization: $e");
    print("[DEBUG] main: Stacktrace: $stacktrace");
  }
}

Future<void> _initializeBackgroundServices(
  NotificationsService notifications,
  FirebaseBackendService firebaseBackend,
) async {
  try {
    await notifications.init();
  } catch (e, st) {
    debugPrint('NotificationsService init failed: $e\n$st');
  }

  try {
    await firebaseBackend.init();
  } catch (e, st) {
    debugPrint('FirebaseBackendService init failed: $e\n$st');
  }
}
