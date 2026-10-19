import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:google_fonts/google_fonts.dart';

// ───────── 하루링과 같은 디자인 값 ─────────
const Color kAccent = Color(0xFF2B2D55); // 짙은 남색 (기본 색)
const Color kIndigo = Color(0xFF5B63F0); // 보라빛 파랑 (포인트)
const Color kMint = Color(0xFF5ED3B1); // 완료 표시
const Color kBand = Color(0xFFF3F4F8); // 구역 사이 연회색 띠
const Color kInk = Color(0xFF23244A); // 글자색
const Color kSubtle = Color(0xFF8A8CA3); // 보조 글자색
const Color kLine = Color(0xFFECEDF3);
const CupertinoDynamicColor kAccentSoft = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFEEF0FF),
  darkColor: Color(0xFFEEF0FF),
);
const CupertinoDynamicColor kAccentDeep = CupertinoDynamicColor.withBrightness(
  color: Color(0xFF5B63F0),
  darkColor: Color(0xFF5B63F0),
);
const CupertinoDynamicColor kHolidayRed = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFD70015),
  darkColor: Color(0xFFFF6961),
);

/// 글자 크기를 한꺼번에 키우는 배율 (하루링과 같은 1.2)
const double kTextBoost = 1.2;

const double kCardRadius = 22;
const List<BoxShadow> kCardShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x141E3250), blurRadius: 18, offset: Offset(0, 6)),
];

const List<String> kWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

// 끼니 아이콘 색
const Color kSunrise = Color(0xFFE9A93A);
const Color kSun = Color(0xFFF08A3C);
const Color kMoon = Color(0xFF5C5BA6);

/// 영문·숫자는 Plus Jakarta Sans, 한글은 Pretendard
TextStyle font(double size, FontWeight weight, {double letterSpacing = 0}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    color: kInk,
  ).copyWith(fontFamilyFallback: const ['Pretendard']);
}

Color secondaryOf(BuildContext c) => kSubtle;
Color labelOf(BuildContext c) => kInk;

BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      borderRadius: BorderRadius.circular(kCardRadius),
      boxShadow: kCardShadow,
    );

/// 안내 창 (오류·알림용)
Future<void> showMessage(BuildContext context, String message, {String? title}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: title == null ? null : Text(title),
      content: Padding(padding: const EdgeInsets.only(top: 6), child: Text(message)),
      actions: [
        CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('확인')),
      ],
    ),
  );
}

// ───────── 구역 (흰 바탕 + 위쪽 연회색 띠) ─────────
class Section extends StatelessWidget {
  const Section({super.key, this.header, this.headerText, required this.children, this.footer, this.indent = 20});
  final Widget? header;
  final String? headerText;
  final List<Widget> children;
  final String? footer;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Container(margin: EdgeInsetsDirectional.only(start: indent), height: 0.5, color: kLine));
      }
      rows.add(children[i]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 8, color: kBand),
      Container(
        color: CupertinoColors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (header != null || headerText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: header ?? Text(headerText!, style: font(15, FontWeight.w700)),
            ),
          ...rows,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(footer!, style: font(12, FontWeight.w400).copyWith(color: kSubtle, height: 1.4)),
            ),
        ]),
      ),
    ]);
  }
}

/// 카드 안의 한 줄 (왼쪽 위젯 + 제목/보조문구 + 오른쪽 위젯)
class Row1 extends StatelessWidget {
  const Row1({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.titleColor,
    this.minHeight = 46,
  });
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? titleColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: font(15, FontWeight.w400, letterSpacing: -0.2)
                        .copyWith(color: titleColor ?? labelOf(context))),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: font(12, FontWeight.w400).copyWith(color: secondary)),
                  ),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// 큰 파란 버튼
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        width: double.infinity,
        child: Text(label, textAlign: TextAlign.center, style: font(16, FontWeight.w600).copyWith(color: CupertinoColors.white)),
      ),
    );
  }
}

class NavTextButton extends StatelessWidget {
  const NavTextButton(this.label, this.onPressed, {super.key, this.bold = false});
  final String label;
  final VoidCallback? onPressed;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
    );
  }
}

// ───────── 방 아이콘 ─────────
class RoomKind {
  const RoomKind(this.key, this.color, this.icon);
  final String key;
  final Color color;
  final IconData icon;
}

const List<RoomKind> kRoomKinds = [
  RoomKind('heart', Color(0xFFFF6B94), CupertinoIcons.heart_fill),
  RoomKind('home', Color(0xFFFF9F0A), CupertinoIcons.house_fill),
  RoomKind('people', Color(0xFF55A0FA), CupertinoIcons.person_3_fill),
  RoomKind('dining', Color(0xFF34B27B), Icons.restaurant_rounded),
];

RoomKind kindOf(String key) => kRoomKinds.firstWhere((k) => k.key == key, orElse: () => kRoomKinds.last);

class RoomIconBox extends StatelessWidget {
  const RoomIconBox({super.key, required this.kind, this.size = 32});
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = kindOf(kind);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: k.color, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(k.icon, color: CupertinoColors.white, size: size * 0.55),
    );
  }
}

// ───────── 멤버 동그라미 ─────────
const List<Color> _avatarColors = [Color(0xFF55A0FA), Color(0xFFFF9F0A), Color(0xFFFF6B94), Color(0xFF8E6BD1)];

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.index, this.isMe = false, this.size = 36});
  final String name;
  final int index;
  final bool isMe;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = isMe ? '나' : (name.isEmpty ? '?' : name.characters.first);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: isMe ? kAccent : _avatarColors[index % _avatarColors.length], shape: BoxShape.circle),
      child: Text(label, style: font(size * 0.4, FontWeight.w700).copyWith(color: CupertinoColors.white)),
    );
  }
}
