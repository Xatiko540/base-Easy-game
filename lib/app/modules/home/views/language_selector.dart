import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/language_service.dart';

void showLanguageSelector(BuildContext context) {
  final languageService = Get.find<LanguageService>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF202223),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: math.min(MediaQuery.sizeOf(context).height * 0.85, 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'language.title'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'language.subtitle'.tr,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      itemCount: LanguageService.supportedLanguages.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _LanguageOption(
                            code: 'system',
                            title: 'language.system'.tr,
                            flag: 'SYS',
                            selected: languageService.useSystem.value,
                          );
                        }

                        final language =
                            LanguageService.supportedLanguages[index - 1];
                        return _LanguageOption(
                          code: language.code,
                          title: language.translationKey.tr,
                          flag: language.badge,
                          selected: !languageService.useSystem.value &&
                              languageService.languageCode.value ==
                                  language.code,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String title;
  final String flag;
  final bool selected;

  const _LanguageOption({
    required this.code,
    required this.title,
    required this.flag,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final languageService = Get.find<LanguageService>();
        if (code == 'system') {
          await languageService.setSystemLanguage();
        } else {
          await languageService.setLanguage(code);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        Get.snackbar(
          code == 'system' ? 'language.systemSaved'.tr : 'language.saved'.tr,
          title,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2F3535) : const Color(0xFF282A2B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF67DCCB) : Colors.white10,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF426CF8),
                shape: BoxShape.circle,
              ),
              child: Text(
                flag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark_circled,
                color: Color(0xFF7CFF85),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
