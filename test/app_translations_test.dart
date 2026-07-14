import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/translations/app_translations.dart';

void main() {
  test('English and Russian translations expose the same keys', () {
    final translations = AppTranslations().keys;
    final englishKeys = translations['en']!.keys.toSet();
    final russianKeys = translations['ru']!.keys.toSet();

    expect(russianKeys.difference(englishKeys), isEmpty);
    expect(englishKeys.difference(russianKeys), isEmpty);
  });
}
