import 'package:flutter/material.dart';

// 목업 색: 청록 포인트 + iOS 그룹 배경
const Color kTeal = Color(0xFF2F7F7A);
const Color kTealSoft = Color(0xFFE3F0EE);
const Color kBg = Color(0xFFF2F2F7);
const Color kInk = Color(0xFF111111);
const Color kMuted = Color(0xFF6C6C70);
const Color kHair = Color(0xFFE2E2E9);
const Color kSunrise = Color(0xFFE9A93A);
const Color kMoon = Color(0xFF5C5BA6);

const double kRadius = 24;

List<BoxShadow> softShadow() => [
      BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
    ];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kTeal, surface: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kBg,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBg,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
