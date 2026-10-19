import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../icons.dart';
import '../models.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> openNotifSettings(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute<void>(builder: (_) => const NotifSettingsPage()));

/// 위쪽이 밝고 아래가 어두운 타원 그라데이션 (목업의 radial-gradient 130% 120% at 50% -10%)
class _Ellipse extends GradientTransform {
  const _Ellipse();

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final r = bounds.shortestSide * 0.5; // RadialGradient(radius: 0.5)가 실제로 쓰는 반지름
    final cx = bounds.left + bounds.width * 0.5;
    final cy = bounds.top - bounds.height * 0.1;
    final sx = bounds.width * 1.3 / r;
    final sy = bounds.height * 1.2 / r;
    return Matrix4.translationValues(cx, cy, 0) *
        Matrix4.diagonal3Values(sx, sy, 1) *
        Matrix4.translationValues(-cx, -cy, 0);
  }
}

class NotifSettingsPage extends StatelessWidget {
  const NotifSettingsPage({super.key});

  Future<void> _update(BuildContext context, void Function(NotifSettings s) edit, {bool turnedOn = false}) async {
    final app = AppScope.read(context);
    final s = app.notif.copy();
    edit(s);
    if (turnedOn) await Notifier.instance.requestPermission();
    await app.saveNotif(s);
  }

  Future<void> _pickTime(BuildContext context, Meal m) async {
    final app = AppScope.read(context);
    final cur = app.notif.minutes[m] ?? m.defaultAlarmMin;
    var picked = cur;
    final base = DateTime(2024, 1, 1);
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 330,
        padding: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
          color: C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Text('${m.label} 알림 시간', style: ts(16, w: FontWeight.w700, lh: 22)),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(ctx).pop(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text('완료', style: ts(16, w: FontWeight.w700, lh: 22, color: C.teal)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minuteInterval: 5,
                initialDateTime: base.add(Duration(minutes: cur - cur % 5)),
                onDateTimeChanged: (d) => picked = d.hour * 60 + d.minute,
              ),
            ),
          ]),
        ),
      ),
    );
    if (ok == true && picked != cur && context.mounted) {
      await _update(context, (s) => s.minutes[m] = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.notif;
    final previewMeal = Meal.forPost(now()) ?? Meal.lunch;

    Widget mealRow(Meal m, {required bool last}) {
      final on = s.on[m] ?? true;
      final min = s.minutes[m] ?? m.defaultAlarmMin;
      return SizedBox(
        height: 64,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              MealBadge(m, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.label, style: ts(15, w: FontWeight.w600, lh: 20)),
                  Text(m.window(spaced: false), maxLines: 1, softWrap: false, style: ts(12, lh: 16, color: C.sub)),
                ]),
              ),
              Semantics(
                button: true,
                label: '${m.label} 알림 시간 ${clockKoMin(min)}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickTime(context, m),
                  child: Opacity(
                    opacity: on ? 1 : 0.45,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: C.fill12, borderRadius: BorderRadius.circular(8)),
                      child: Text(clockKoMin(min), style: ts(15, lh: 20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              MSwitch(
                label: '${m.label} 알림',
                value: on,
                onChanged: (v) => _update(context, (n) => n.on[m] = v, turnedOn: v),
              ),
            ]),
          ),
          if (!last) const Positioned(left: 56, right: 0, bottom: 0, child: HairLine()),
        ]),
      );
    }

    Widget otherRow(String title, String sub, bool value, ValueChanged<bool> onChanged, {required bool last}) {
      return SizedBox(
        height: 60,
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: ts(15, lh: 20)),
                  Text(sub, style: ts(12, lh: 16, color: C.sub)),
                ]),
              ),
              const SizedBox(width: 12),
              MSwitch(label: title, value: value, onChanged: onChanged),
            ]),
          ),
          if (!last) const Positioned(left: 16, right: 0, bottom: 0, child: HairLine()),
        ]),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: C.bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(height: topPad(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 44,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GlassIconButton(icon: Ic.chevLeft, label: '오늘로 돌아가기', size: 22, onTap: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          const HeaderTitle(sub: '식사 시간에 맞춰 알려줘요', title: '알림'),
          const SectionLabel('알림 미리보기', top: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const RadialGradient(
                center: Alignment(0, -1.2),
                radius: 0.5,
                colors: [Color(0xFF3E6AA8), Color(0xFF1F3A66), Color(0xFF0E192F)],
                stops: [0, 0.45, 1],
                transform: _Ellipse(),
              ),
              boxShadow: kCardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x38FFFFFF), width: 0.5),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const AppMark(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Text('냠냠 시간', style: ts(15, w: FontWeight.w700, lh: 20, color: C.white)),
                          const SizedBox(width: 4),
                          const MIcon(Ic.spoonPin, size: 15),
                        ]),
                        Text('${previewMeal.label} 뭐먹어요?', style: ts(15, lh: 20, color: const Color(0xF2FFFFFF))),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text('지금', style: ts(12, lh: 16, color: const Color(0xB3FFFFFF))),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          const SectionLabel('식사 알림', top: 20),
          CardBox(
            clip: true,
            child: Column(children: [
              for (var i = 0; i < Meal.values.length; i++) mealRow(Meal.values[i], last: i == Meal.values.length - 1),
            ]),
          ),
          const FooterNote('왼쪽은 올릴 수 있는 시간, 오른쪽은 알림 시간이에요.'),
          const SectionLabel('그 밖의 알림', top: 20),
          CardBox(
            clip: true,
            child: Column(children: [
              otherRow('마감 30분 전 알림', '아직 안 올린 식사만 알려줘요', s.deadline,
                  (v) => _update(context, (n) => n.deadline = v, turnedOn: v),
                  last: false),
              otherRow('방 사람이 올렸을 때', '누가 올리면 바로 알려줘요', s.peer,
                  (v) => _update(context, (n) => n.peer = v, turnedOn: v),
                  last: true),
            ]),
          ),
        ]),
      ),
    );
  }
}
