import 'package:flutter/material.dart';

import 'theme.dart';

// ───────── 방 아이콘 (색 네모 + 흰 아이콘) ─────────
class RoomKind {
  const RoomKind(this.key, this.color, this.icon);
  final String key;
  final Color color;
  final IconData icon;
}

const List<RoomKind> kRoomKinds = [
  RoomKind('heart', Color(0xFFFF6B94), Icons.favorite_rounded),
  RoomKind('home', Color(0xFFFF9F0A), Icons.home_rounded),
  RoomKind('people', Color(0xFF7FC4F5), Icons.groups_rounded),
  RoomKind('dining', kDeep, Icons.restaurant_rounded),
];

RoomKind kindOf(String key) =>
    kRoomKinds.firstWhere((k) => k.key == key, orElse: () => kRoomKinds.last);

class RoomIconBox extends StatelessWidget {
  const RoomIconBox({super.key, required this.kind, this.size = 40, this.radius});
  final String kind;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final k = kindOf(kind);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: k.color, borderRadius: BorderRadius.circular(radius ?? size * 0.3)),
      child: Icon(k.icon, color: Colors.white, size: size * 0.55),
    );
  }
}

// ───────── 멤버 동그라미 ─────────
const List<Color> _avatarColors = [
  Color(0xFF5AA9F0), Color(0xFFFF9F0A), Color(0xFFFF6B94), Color(0xFF8E6BD1),
];

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, required this.index, this.isMe = false, this.size = 52});
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
      decoration: BoxDecoration(
        color: isMe ? kTeal : _avatarColors[index % _avatarColors.length],
        shape: BoxShape.circle,
        boxShadow: softShadow(),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
    );
  }
}

class EmptySeat extends StatelessWidget {
  const EmptySeat({super.key, this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.add_rounded, color: Color(0xFFB0B0B6)),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7C7CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = size.width / 2 - 1;
    final c = Offset(size.width / 2, size.height / 2);
    const n = 28;
    for (var i = 0; i < n; i++) {
      final a = 2 * 3.1415926 * i / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 2 * 3.1415926 / n * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ───────── 큰 버튼 ─────────
class BigButton extends StatelessWidget {
  const BigButton({super.key, required this.label, required this.onPressed, this.filled = true});
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = enabled && filled ? kTeal : Colors.white;
    final fg = enabled ? (filled ? Colors.white : kInk) : const Color(0xFFA0A0A5);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(27), boxShadow: softShadow()),
        child: Text(label, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFEFEFF2), borderRadius: BorderRadius.circular(23)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: kTeal),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.dot = false, this.size = 44});
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: softShadow()),
        child: Stack(alignment: Alignment.center, children: [
          Icon(icon, size: size * 0.5, color: kInk),
          if (dot)
            Positioned(
              top: size * 0.2,
              right: size * 0.22,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle)),
            ),
        ]),
      ),
    );
  }
}

// ───────── 접시 배너 (방 만들기·초대 화면 위쪽) ─────────
class FoodBanner extends StatelessWidget {
  const FoodBanner({super.key, this.height = 112, this.child});
  final double height;
  final Widget? child;

  static const _plates = [
    ['🥗', Color(0xFFE9EFDD)],
    ['🍱', Color(0xFFF6EBD3)],
    ['🍲', Color(0xFF3B3F4A)],
    ['🍜', Color(0xFFF2D9D4)],
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius),
      child: SizedBox(
        height: height,
        child: Stack(fit: StackFit.expand, children: [
          Row(children: [
            for (final p in _plates)
              Expanded(
                child: Container(
                  color: p[1] as Color,
                  alignment: Alignment.center,
                  child: Container(
                    width: height * 0.72,
                    height: height * 0.72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Text(p[0] as String, style: TextStyle(fontSize: height * 0.4)),
                  ),
                ),
              ),
          ]),
          if (child != null) child!,
        ]),
      ),
    );
  }
}

// ───────── 상단 3칸짜리 세그먼트 ─────────
class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.labels, required this.index, required this.onChanged, this.onAdd});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0xFFE2E2E9), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == index ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: i == index ? softShadow() : null,
                ),
                child: Text(labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          ),
        if (onAdd != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAdd,
            child: const SizedBox(width: 36, child: Icon(Icons.add_rounded, size: 20, color: kMuted)),
          ),
      ]),
    );
  }
}

// ───────── 코드 글자 칸 ─────────
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({super.key, required this.code, this.length = 8, this.activeIndex, this.size = 34});
  final String code;
  final int length;
  final int? activeIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget box(int i) {
      final ch = i < code.length ? code[i] : '';
      final active = activeIndex == i;
      return Container(
        width: size,
        height: size * 1.3,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ch.isEmpty ? const Color(0xFFE8E8ED) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? kTeal : Colors.transparent, width: 1.8),
          boxShadow: ch.isEmpty ? null : softShadow(),
        ),
        child: Text(ch, style: TextStyle(fontSize: size * 0.6, fontWeight: FontWeight.w800)),
      );
    }

    final half = length ~/ 2;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < half; i++) box(i),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('-', style: TextStyle(color: Color(0xFFB0B0B6))),
      ),
      for (var i = half; i < length; i++) box(i),
    ]);
  }
}
