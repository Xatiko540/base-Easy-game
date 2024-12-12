// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import '../modules/home/views/home_view.dart';
import '../modules/home/views/levels.dart';


part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;


  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      // page: () => LevelsScreen(),

    ),


  ];
}
