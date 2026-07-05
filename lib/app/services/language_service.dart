import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageService extends GetxService {
  static const _storageKey = 'app_language';
  static const _systemCode = 'system';
  static const supportedCodes = {'en', 'ru'};

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
    final deviceCode = Get.deviceLocale?.languageCode;
    return deviceCode == 'ru' ? 'ru' : 'en';
  }
}
