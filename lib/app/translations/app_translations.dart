import 'package:get/get.dart';

import 'arabic_translations.dart';
import 'chinese_translations.dart';
import 'english_translations.dart';
import 'french_translations.dart';
import 'hindi_translations.dart';
import 'italian_translations.dart';
import 'japanese_translations.dart';
import 'korean_translations.dart';
import 'portuguese_translations.dart';
import 'russian_translations.dart';
import 'spanish_translations.dart';
import 'turkish_translations.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': englishTranslations,
        'ru': russianTranslations,
        'zh': chineseTranslations,
        'ar': arabicTranslations,
        'es': spanishTranslations,
        'fr': frenchTranslations,
        'pt': portugueseTranslations,
        'hi': hindiTranslations,
        'ja': japaneseTranslations,
        'tr': turkishTranslations,
        'ko': koreanTranslations,
        'it': italianTranslations,
      };
}
