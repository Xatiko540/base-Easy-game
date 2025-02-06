import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:lottery_advance/utils/theme.dart';

import 'app/modules/controller/lotteries_controller.dart';
import 'app/routes/app_pages.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final matrix = BinaryMatrix();
  matrix.fillMatrix(6); // Заполняем 6 уровней
  matrix.printMatrix();

  runApp(
    GetMaterialApp(
      title: "Easy game",
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
    ),
  );
}
