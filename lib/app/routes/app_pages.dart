// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';

import 'package:lottery_advance/app/modules/home/views/home_view.dart';

import '../modules/home/views/levels.dart';
import '../modules/home/views/profilescreen.dart';
import '../modules/home/views/start page.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;


  static final routes = [
    GetPage(
      name: _Paths.HOME,
      // page: () => HomeView(),
      page: () => ProfileScreen(),

    ),


  ];
}
