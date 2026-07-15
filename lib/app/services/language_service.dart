import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.translationKey,
    required this.badge,
  });

  final String code;
  final String translationKey;
  final String badge;
}

class LanguageService extends GetxService {
  static const _storageKey = 'app_language';
  static const _systemCode = 'system';
  static const supportedLanguages = <AppLanguage>[
    AppLanguage(code: 'en', translationKey: 'language.english', badge: 'EN'),
    AppLanguage(code: 'ru', translationKey: 'language.russian', badge: 'RU'),
    AppLanguage(code: 'zh', translationKey: 'language.chinese', badge: 'ZH'),
    AppLanguage(code: 'ar', translationKey: 'language.arabic', badge: 'AR'),
    AppLanguage(code: 'es', translationKey: 'language.spanish', badge: 'ES'),
    AppLanguage(code: 'fr', translationKey: 'language.french', badge: 'FR'),
    AppLanguage(
      code: 'pt',
      translationKey: 'language.portuguese',
      badge: 'PT',
    ),
    AppLanguage(code: 'hi', translationKey: 'language.hindi', badge: 'HI'),
    AppLanguage(code: 'ja', translationKey: 'language.japanese', badge: 'JA'),
    AppLanguage(code: 'tr', translationKey: 'language.turkish', badge: 'TR'),
    AppLanguage(code: 'ko', translationKey: 'language.korean', badge: 'KO'),
    AppLanguage(code: 'it', translationKey: 'language.italian', badge: 'IT'),
  ];
  static const supportedCodes = {
    'en',
    'ru',
    'zh',
    'ar',
    'es',
    'fr',
    'pt',
    'hi',
    'ja',
    'tr',
    'ko',
    'it',
  };
  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('zh'),
    Locale('ar'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('hi'),
    Locale('ja'),
    Locale('tr'),
    Locale('ko'),
    Locale('it'),
  ];

  final GetStorage _storage = GetStorage();
  final RxString languageCode = 'en'.obs;
  final RxBool useSystem = true.obs;

  Locale get locale => Locale(languageCode.value);
  bool get isRussian => languageCode.value == 'ru';

  void load() {
    final stored = _storage.read<String>(_storageKey);
    if (stored == null || stored == _systemCode) {
      useSystem.value = true;
      languageCode.value = _detectSystemLanguage();
      return;
    }

    if (supportedCodes.contains(stored)) {
      useSystem.value = false;
      languageCode.value = stored;
      return;
    }

    useSystem.value = true;
    languageCode.value = _detectSystemLanguage();
  }

  Future<void> setLanguage(String code) async {
    if (!supportedCodes.contains(code)) {
      return;
    }
    useSystem.value = false;
    languageCode.value = code;
    await _storage.write(_storageKey, code);
    Get.updateLocale(Locale(code));
  }

  Future<void> setSystemLanguage() async {
    final code = _detectSystemLanguage();
    useSystem.value = true;
    languageCode.value = code;
    await _storage.write(_storageKey, _systemCode);
    Get.updateLocale(Locale(code));
  }

  void refreshSystemLanguage() {
    if (!useSystem.value) {
      return;
    }
    final code = _detectSystemLanguage();
    if (languageCode.value == code) {
      return;
    }
    languageCode.value = code;
    Get.updateLocale(Locale(code));
  }

  String _detectSystemLanguage() {
    final deviceCode = Get.deviceLocale?.languageCode.toLowerCase();
    return supportedCodes.contains(deviceCode) ? deviceCode! : 'en';
  }
}
