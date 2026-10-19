import 'package:flutter/cupertino.dart';

/// 목업에서 그대로 가져온 색
abstract final class C {
  static const bg = Color(0xFFF3EEE5); // 따뜻한 종이톤
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const accent = Color(0xFF14201E); // 메인 포인트(먹색)
  static const lime = Color(0xFFD9F66B); // 눌러야 할 곳에만 쓰는 라임
  static const amber = Color(0xFFE5A23F); // 아침
  static const indigo = Color(0xFF5C5BA6); // 저녁
  static const ink = Color(0xFF1C1C1E);
  static const ink3 = Color(0xFF3A3A3C);
  static const ink6 = Color(0xFF636366);
  static const sub = Color(0xFF6C6C70); // 보조 글자
  static const gray8 = Color(0xFF8E8E93);
  static const grayAE = Color(0xFFAEAEB2);
  static const grayC7 = Color(0xFFC7C7CC);
  static const track = Color(0xFFEBEBF0); // 알약·버튼 바탕
  static const emptyTile = Color(0xFFEEEEF3);
  static const dash = Color(0xFFB8B8C0);
  static const sep = Color(0xFFE5E5EA);
  static const red = Color(0xFFD92D20);
  static const pink = Color(0xFFFF6B94);
  static const orange = Color(0xFFFF9F0A);
  static const blue = Color(0xFF5AA9F0);
  static const fill12 = Color.fromRGBO(118, 118, 128, 0.12);
  static const fill16 = Color.fromRGBO(120, 120, 128, 0.16);
  static const fill10 = Color.fromRGBO(118, 118, 128, 0.10);
}

/// 목업의 글자 스타일. [lh]는 CSS의 line-height(px)와 같은 값이에요.
TextStyle ts(
  double size, {
  FontWeight w = FontWeight.w400,
  Color color = C.black,
  double? lh,
  double ls = 0,
}) {
  return TextStyle(
    inherit: false,
    fontFamily: 'PlusJakartaSans',
    fontFamilyFallback: const ['Pretendard'],
    fontSize: size,
    fontWeight: w,
    color: color,
    height: lh == null ? null : lh / size,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: ls,
    decoration: TextDecoration.none,
  );
}

const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 0, spreadRadius: 0.5),
  BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x0F1E325A), offset: Offset(0, 3), blurRadius: 8),
];

const List<BoxShadow> kGlassShadow = [
  BoxShadow(color: Color(0x1A1E2846), offset: Offset(0, 3), blurRadius: 8),
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 2),
];

const List<BoxShadow> kCtaShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 0, spreadRadius: 0.5),
  BoxShadow(color: Color(0x1A1E2846), offset: Offset(0, 2), blurRadius: 6),
];

const List<BoxShadow> kThumbShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 0, spreadRadius: 0.5),
];
