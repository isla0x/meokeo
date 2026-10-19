import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:path_drawing/path_drawing.dart';

import 'icons.dart';
import 'models.dart';
import 'theme.dart';

// ───────────────────────── 유리 느낌 (반투명 + 흐림) ─────────────────────────

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.circle = false,
    this.blur = 20,
    this.alpha = 0.68,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.shadows = kGlassShadow,
  });

  final Widget child;
  final double radius;
  final bool circle;
  final double blur;
  final double alpha;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final BorderRadius? br = circle ? null : BorderRadius.circular(radius);
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;
    final inner = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, alpha),
        shape: shape,
        borderRadius: br,
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.8), width: 0.5),
      ),
      child: child,
    );
    final Widget clipped = circle
        ? ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: inner))
        : ClipRRect(
            borderRadius: br!,
            child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: inner),
          );
    final boxed = DecoratedBox(
      decoration: BoxDecoration(shape: shape, borderRadius: br, boxShadow: shadows),
      child: clipped,
    );
    if (onTap == null) return boxed;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: boxed);
  }
}

/// 위쪽 둥근 버튼 (방 멤버, 알림, 뒤로가기)
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 24});
  final IconSpec icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Glass(circle: true, width: 44, height: 44, onTap: onTap, child: MIcon(icon, size: size)),
    );
  }
}

// ───────────────────────── 카드 ─────────────────────────

class CardBox extends StatelessWidget {
  const CardBox({
    super.key,
    required this.child,
    this.radius = 24,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.padding,
    this.clip = false,
    this.color = C.white,
    this.shadows = kCardShadow,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry? padding;
  final bool clip;
  final Color color;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget c = child;
    if (padding != null) c = Padding(padding: padding!, child: c);
    if (clip) c = ClipRRect(borderRadius: br, child: c);
    return Container(
      margin: margin,
      decoration: BoxDecoration(color: color, borderRadius: br, boxShadow: shadows),
      child: c,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 16, this.bottom = 6});
  final String text;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(36, top, 36, bottom),
        child: Text(text, style: ts(12, lh: 16, color: C.sub)),
      );
}

class FooterNote extends StatelessWidget {
  const FooterNote(this.text, {super.key, this.top = 8});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(36, top, 36, 0),
        child: Text(text, style: ts(12, lh: 16, color: C.sub)),
      );
}

class HeaderTitle extends StatelessWidget {
  const HeaderTitle({super.key, required this.sub, required this.title});
  final String sub;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sub, style: ts(12, w: FontWeight.w600, lh: 16, color: C.sub)),
          Text(title, style: ts(28, w: FontWeight.w700, lh: 34, ls: 0.37)),
        ]),
      );
}

/// 위쪽 안전 영역 + 9px (목업의 상태바 아래 여백)
double topPad(BuildContext context) => MediaQuery.paddingOf(context).top + 9;

// ───────────────────────── 스위치 · 구분 막대 ─────────────────────────

class MSwitch extends StatelessWidget {
  const MSwitch({super.key, required this.value, required this.onChanged, this.label});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 51,
          height: 31,
          decoration: BoxDecoration(
            color: value ? C.teal : C.fill16,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              top: 2,
              left: value ? 22 : 2,
              child: Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  color: C.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x24000000), offset: Offset(0, 2), blurRadius: 4),
                    BoxShadow(color: Color(0x24000000), offset: Offset(0, 1), blurRadius: 1),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class HairLine extends StatelessWidget {
  const HairLine({super.key, this.left = 0});
  final double left;

  @override
  Widget build(BuildContext context) =>
      Container(margin: EdgeInsets.only(left: left), height: 0.5, color: C.sep);
}

// ───────────────────────── 끼니 배지 · 사진 칸 ─────────────────────────

class MealBadge extends StatelessWidget {
  const MealBadge(this.meal, {super.key, required this.size});
  final Meal meal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: meal.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: meal.color, borderRadius: BorderRadius.circular((size * 0.3).roundToDouble())),
        alignment: Alignment.center,
        child: MIcon(meal.glyph, size: (size * 0.7).roundToDouble()),
      ),
    );
  }
}

/// 방 아이콘의 흰 그림만
class RoomBadgeGlyph extends StatelessWidget {
  const RoomBadgeGlyph(this.icon, {super.key, required this.glyph});
  final RoomIcon icon;
  final double glyph;

  @override
  Widget build(BuildContext context) {
    final spec = switch (icon) {
      RoomIcon.heart => Ic.heart,
      RoomIcon.house => Ic.house,
      RoomIcon.people => Ic.people,
      RoomIcon.dining => Ic.dining,
    };
    return icon == RoomIcon.dining ? MIcon(spec, height: glyph * 1.2) : MIcon(spec, size: glyph);
  }
}

/// 방 아이콘 (색 네모 + 흰 그림)
class RoomBadge extends StatelessWidget {
  const RoomBadge(this.icon, {super.key, required this.size, this.glyph, this.radius});
  final RoomIcon icon;
  final double size;
  final double? glyph;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: icon.color, borderRadius: BorderRadius.circular(radius ?? size * 0.27)),
      alignment: Alignment.center,
      child: RoomBadgeGlyph(icon, glyph: glyph ?? size * 0.56),
    );
  }
}

/// 안 올린 칸 (회색 + 가운데 줄)
class EmptyTile extends StatelessWidget {
  const EmptyTile({super.key, this.radius = 12, this.dashWidth = 14});
  final double radius;
  final double dashWidth;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: C.emptyTile, borderRadius: BorderRadius.circular(radius)),
        alignment: Alignment.center,
        child: Container(
          width: dashWidth,
          height: 2,
          decoration: BoxDecoration(color: C.dash, borderRadius: BorderRadius.circular(1)),
        ),
      );
}

class PhotoFill extends StatelessWidget {
  const PhotoFill(this.image, {super.key});
  final ImageProvider image;

  @override
  Widget build(BuildContext context) => Image(
        image: image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
}

class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.image, {super.key, this.radius = 12, this.onTap});
  final ImageProvider image;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: kThumbShadow),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: PhotoFill(image)),
    );
    return onTap == null ? w : GestureDetector(onTap: onTap, child: w);
  }
}

// ───────────────────────── 버튼 ─────────────────────────

/// 아래쪽 흰 알약 버튼 (목업의 "방 만들기", "완료", "올리기")
class CtaButton extends StatelessWidget {
  const CtaButton({super.key, required this.label, required this.onTap, this.enabled = true});
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(27), boxShadow: kCtaShadow),
          child: Text(label, style: ts(15, w: FontWeight.w700, lh: 20, color: enabled ? C.sub : C.grayAE)),
        ),
      ),
    );
  }
}

/// 회색 알약 버튼 (코드 복사 · 공유하기)
class SoftPill extends StatelessWidget {
  const SoftPill({super.key, required this.icon, required this.label, required this.onTap});
  final IconSpec icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: C.fill12, borderRadius: BorderRadius.circular(22)),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          MIcon(icon, size: 18),
          const SizedBox(width: 7),
          Text(label, style: ts(15, w: FontWeight.w600, lh: 20, color: C.ink3)),
        ]),
      ),
    );
  }
}

// ───────────────────────── 방 고르는 분할 막대 ─────────────────────────

class RoomSegments extends StatelessWidget {
  const RoomSegments({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.onAdd,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// 방이 3개보다 적을 때 끝에 붙는 "+" 칸
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final on = i == selected;
      items.add(Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onSelect(i),
          child: Container(
            height: 28,
            alignment: Alignment.center,
            decoration: on
                ? BoxDecoration(
                    color: C.white,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), offset: Offset(0, 2), blurRadius: 4),
                      BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 1),
                    ],
                  )
                : null,
            child: Text(labels[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(13, w: on ? FontWeight.w600 : FontWeight.w500, lh: 18)),
          ),
        ),
      ));
    }
    if (onAdd != null) {
      items.add(SizedBox(
        width: 44,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAdd,
          child: Container(height: 28, alignment: Alignment.center, child: const MIcon(Ic.plusGray, size: 16)),
        ),
      ));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: C.fill12, borderRadius: BorderRadius.circular(9)),
      child: Row(children: items),
    );
  }
}

// ───────────────────────── 아래 알약 탭바 + 카메라 ─────────────────────────

class PillBar extends StatelessWidget {
  const PillBar({super.key, required this.index, required this.onTab, required this.onCamera});
  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i, String label, IconSpec on, IconSpec off) {
      final active = index == i;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTab(i),
          child: Container(
            decoration: active
                ? BoxDecoration(color: C.track, borderRadius: BorderRadius.circular(27))
                : null,
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              MIcon(active ? on : off, size: 28),
              const SizedBox(height: 2),
              Text(label, style: ts(10, w: active ? FontWeight.w600 : FontWeight.w500, lh: 12, color: C.sub)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      Expanded(
        child: Glass(
          radius: 32,
          height: 64,
          padding: const EdgeInsets.all(5),
          child: Row(children: [
            tab(0, '오늘', Ic.bowlOn, Ic.bowlOff),
            tab(1, '캘린더', Ic.calOn, Ic.calOff),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      Semantics(
        button: true,
        label: '지금 먹는 거 올리기',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onCamera,
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: C.track, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const MIcon(Ic.camera, size: 30),
          ),
        ),
      ),
    ]);
  }
}

// ───────────────────────── 앱 아이콘 모양 (알림 미리보기 등) ─────────────────────────

class AppMark extends StatelessWidget {
  const AppMark({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.225),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F5F8)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 0, spreadRadius: 0.5)],
      ),
      alignment: Alignment.center,
      child: MIcon(Ic.diningGrad, height: size * 0.48),
    );
  }
}

// ───────────────────────── 아래 시트 (취소 / 제목) ─────────────────────────

Future<T?> showMSheet<T>(BuildContext context, WidgetBuilder builder) {
  return Navigator.of(context, rootNavigator: true).push<T>(_SheetRoute<T>(builder));
}

class _SheetRoute<T> extends PopupRoute<T> {
  _SheetRoute(this.builder);
  final WidgetBuilder builder;

  @override
  Color? get barrierColor => const Color(0x8C000000);
  @override
  bool get barrierDismissible => false;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondary) =>
      builder(context);

  @override
  Widget buildTransitions(
      BuildContext context, Animation<double> animation, Animation<double> secondary, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
      child: child,
    );
  }
}

/// 목업의 시트: 위가 크게 둥글고, 맨 위에 손잡이와 [취소] [제목]
class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.cancelLabel = '취소',
    this.onCancel,
  });

  final String title;
  final Widget child;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 7;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        child: Container(
          color: C.bg,
          child: Column(children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) > 400) (onCancel ?? () => Navigator.of(context).maybePop())();
              },
              child: Column(children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: C.grayC7, borderRadius: BorderRadius.circular(3)),
                ),
                SizedBox(
                  height: 52,
                  child: Stack(alignment: Alignment.center, children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Glass(
                          radius: 18,
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onTap: onCancel ?? () => Navigator.of(context).maybePop(),
                          child: Text(cancelLabel, style: ts(15, w: FontWeight.w600, lh: 20, color: C.sub)),
                        ),
                      ),
                    ),
                    IgnorePointer(child: Text(title, style: ts(15, w: FontWeight.w600, lh: 20))),
                  ]),
                ),
              ]),
            ),
            Expanded(child: child),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── 알림창 · 토스트 ─────────────────────────

Future<void> showAlert(BuildContext context, String message, {String? title}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
      ],
    ),
  );
}

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String okLabel,
  bool destructive = false,
}) async {
  final r = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(okLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

void showToast(BuildContext context, String text) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Toast(text: text, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.text, required this.onDone});
  final String text;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  double _o = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _o = 1);
    });
    _t = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _o = 0);
      Timer(const Duration(milliseconds: 260), widget.onDone);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 118,
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: _o,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xE61C1C1E), borderRadius: BorderRadius.circular(20)),
              child: Text(widget.text, style: ts(14, w: FontWeight.w600, lh: 20, color: C.white)),
            ),
          ),
        ),
      ),
    );
  }
}


// ───────────────────────── 점선 동그라미 (빈 자리) ─────────────────────────

class DashedRing extends StatelessWidget {
  const DashedRing({super.key, required this.size, this.color = C.dash, this.stroke = 1.5, this.child});
  final double size;
  final Color color;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingPainter(color, stroke), child: Center(child: child)),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.stroke);
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final path = Path()..addOval(r);
    canvas.drawPath(
      dashPath(path, dashArray: CircularIntervalList<double>(<double>[stroke * 2.4, stroke * 2])),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.color != color || old.stroke != stroke;
}

/// 초대 코드 한 칸 (흰 네모 + 큰 글자)
class CodeBox extends StatelessWidget {
  const CodeBox({super.key, this.char, this.width = 32, this.height = 42, this.fontSize = 20, this.active = false, this.empty = false});
  final String? char;
  final double width;
  final double height;
  final double fontSize;
  final bool active; // 지금 입력할 칸
  final bool empty; // 아직 비어 있는 칸 (회색)

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: empty ? C.fill10 : C.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: active
            ? const [BoxShadow(color: C.teal, spreadRadius: 2)]
            : empty
                ? null
                : const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 0, spreadRadius: 0.5),
                    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 1), blurRadius: 2),
                  ],
      ),
      child: active && (char == null || char!.isEmpty)
          ? Container(width: 2, height: 28, decoration: BoxDecoration(color: C.teal, borderRadius: BorderRadius.circular(1)))
          : Text(char ?? '', style: ts(fontSize, w: FontWeight.w700, lh: 24)),
    );
  }
}

/// 4자 - 4자 모양으로 코드 칸을 늘어놓아요
class CodeRow extends StatelessWidget {
  const CodeRow({super.key, required this.chars, this.width = 32, this.height = 42, this.fontSize = 20, this.activeIndex = -1});
  final List<String?> chars; // 길이 8, 비어 있으면 null
  final double width;
  final double height;
  final double fontSize;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    for (var i = 0; i < kCodeLength; i++) {
      if (i == 4) {
        kids.add(const SizedBox(width: 5));
        kids.add(SizedBox(
          width: 10,
          child: Center(
            child: Container(width: 6, height: 2, decoration: BoxDecoration(color: C.grayC7, borderRadius: BorderRadius.circular(1))),
          ),
        ));
        kids.add(const SizedBox(width: 5));
      } else if (i > 0) {
        kids.add(const SizedBox(width: 5));
      }
      final c = i < chars.length ? chars[i] : null;
      kids.add(CodeBox(
        char: c,
        width: width,
        height: height,
        fontSize: fontSize,
        active: i == activeIndex,
        empty: activeIndex >= 0 && c == null && i != activeIndex,
      ));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: kids);
  }
}
