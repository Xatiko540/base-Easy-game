import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EasyGameTheme {
  static const Color page = Color(0xFF111313);
  static const Color shell = Color(0xFF141515);
  static const Color surface = Color(0xFF1F2223);
  static const Color surfaceHigh = Color(0xFF242526);
  static const Color card = Color(0xFF343637);
  static const Color cardDark = Color(0xFF171818);
  static const Color border = Color(0xFF2B2D2F);
  static const Color borderSoft = Color(0xFF34383A);
  static const Color teal = Color(0xFF20C7AD);
  static const Color tealSoft = Color(0xFF5ED6C1);
  static const Color purple = Color(0xFF9B16C9);
  static const Color blue = Color(0xFF426CF8);
  static const Color gold = Color(0xFFF7C948);
  static const Color orange = Color(0xFFFFA733);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9B9B9B);
  static const Color textDim = Color(0xFF6F7375);

  static const LinearGradient actionGradient = LinearGradient(
    colors: [purple, Color(0xFF4968C9), teal],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardBorderGradient = LinearGradient(
    colors: [teal, blue, purple],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const RadialGradient shellGlow = RadialGradient(
    center: Alignment(0.56, 0.6),
    radius: 0.95,
    colors: [
      Color(0xDD0F9D8B),
      Color(0xFF1A2422),
      page,
    ],
    stops: [0, 0.45, 1],
  );
}

const primaryColor = EasyGameTheme.purple;
const secondaryColor = EasyGameTheme.teal;
const secondarySplashColor = Color(0x555ED6C1);
const splashColor = Color(0x33426CF8);

final lightTheme = ThemeData(
  fontFamily: GoogleFonts.poppins().fontFamily,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: EasyGameTheme.page,
  colorScheme: ColorScheme.fromSeed(
    seedColor: EasyGameTheme.teal,
    brightness: Brightness.dark,
  ),
  splashColor: splashColor,
  useMaterial3: true,
);
final darkTheme = ThemeData(
  fontFamily: GoogleFonts.poppins().fontFamily,
  primaryColor: primaryColor,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: EasyGameTheme.page,
  colorScheme: ColorScheme.fromSeed(
    seedColor: EasyGameTheme.teal,
    brightness: Brightness.dark,
    primary: EasyGameTheme.teal,
    secondary: EasyGameTheme.purple,
    surface: EasyGameTheme.surface,
  ),
  cardColor: EasyGameTheme.surface,
  splashColor: splashColor,
  useMaterial3: true,
);
