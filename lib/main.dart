import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/notifications_service.dart';
import 'package:lottery_advance/app/services/contract_events_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
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

    NotificationsService? notifications;
    ContractEventsService? contractEvents;

    if (!kIsWeb) {
      print(
          "[DEBUG] main: Non-web platform detected. Initializing mobile services...");
      notifications = NotificationsService();
      Get.put(notifications, permanent: true);
      contractEvents = ContractEventsService(
        walletService: Get.find<WalletConnectService>(),
        notifications: notifications,
      );
      Get.put(contractEvents, permanent: true);
      print("[DEBUG] main: Mobile services registered.");
    } else {
      print("[DEBUG] main: Web platform detected.");
    }

    print("[DEBUG] main: Running runApp...");
    runApp(
      GetMaterialApp(
        title: "Easy game",
        initialRoute: ReferralLinkService.isReferralEntryUri(Uri.base)
            ? Routes.INVITE
            : AppPages.INITIAL,
        getPages: AppPages.routes,
        defaultTransition: Transition.fadeIn,
        theme: lightTheme,
        darkTheme: darkTheme,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
      ),
    );
    print("[DEBUG] main: runApp executed.");

    if (!kIsWeb && notifications != null && contractEvents != null) {
      print("[DEBUG] main: Initializing background services...");
      _initializeBackgroundServices(notifications, contractEvents);
    }
  } catch (e, stacktrace) {
    print("[DEBUG] main: FATAL ERROR during initialization: $e");
    print("[DEBUG] main: Stacktrace: $stacktrace");
  }
}

Future<void> _initializeBackgroundServices(
  NotificationsService notifications,
  ContractEventsService contractEvents,
) async {
  try {
    await notifications.init();
  } catch (e, st) {
    debugPrint('NotificationsService init failed: $e\n$st');
  }

  try {
    await contractEvents.init();
  } catch (e, st) {
    debugPrint('ContractEventsService init failed: $e\n$st');
  }
}
