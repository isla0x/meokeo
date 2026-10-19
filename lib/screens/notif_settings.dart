import 'package:flutter/cupertino.dart';

import '../notifications.dart';
import '../posts.dart';
import '../ui.dart';

class NotifSettingsScreen extends StatefulWidget {
  const NotifSettingsScreen({super.key});

  @override
  State<NotifSettingsScreen> createState() => _NotifSettingsScreenState();
}

class _NotifSettingsScreenState extends State<NotifSettingsScreen> {
  Map<Meal, MealAlarm>? _alarms;

  @override
  void initState() {
    super.initState();
    Notifier.instance.load().then((a) {
      if (mounted) setState(() => _alarms = a);
    });
  }

  String _fmt(MealAlarm a) {
    final h = a.hour;
    final ap = h < 12 ? '오전' : '오후';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$ap $h12:${a.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle(Meal m, bool on) async {
    final a = _alarms!;
    if (on) {
      final ok = await Notifier.instance.requestPermission();
      if (!ok) {
        if (mounted) showMessage(context, '알림 권한이 꺼져 있어요. 설정 → 뭐먹어? → 알림에서 켜 주세요.');
        return;
      }
    }
    setState(() => a[m]!.enabled = on);
    await Notifier.instance.save(a);
  }

  void _pick(Meal m) {
    final a = _alarms!;
    var picked = DateTime(2000, 1, 1, a[m]!.hour, a[m]!.minute);
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            NavTextButton('취소', () => Navigator.pop(ctx)),
            Text('${m.label} 알림 시간', style: font(15, FontWeight.w600)),
            NavTextButton('확인', () async {
              Navigator.pop(ctx);
              setState(() {
                a[m]!.hour = picked.hour;
                a[m]!.minute = picked.minute;
              });
              await Notifier.instance.save(a);
            }, bold: true),
          ]),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: picked,
              minuteInterval: 5,
              onDateTimeChanged: (d) => picked = d,
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _alarms;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text('알림 시간'),
          backgroundColor: CupertinoColors.systemGroupedBackground,
        ),
        SliverToBoxAdapter(
          child: a == null
              ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()))
              : Section(
                  footer: '정해진 시간에 "뭐 먹었어?" 알림이 와요. 알림은 이 폰에서만 예약되고, 서버로 보내지 않아요.',
                  children: [
                    for (final m in Meal.values)
                      Row1(
                        minHeight: 56,
                        leading: Icon(m.icon, size: 20, color: m.color),
                        title: m.label,
                        subtitle: _fmt(a[m]!),
                        onTap: () => _pick(m),
                        trailing: CupertinoSwitch(
                          value: a[m]!.enabled,
                          activeTrackColor: kAccent,
                          onChanged: (v) => _toggle(m, v),
                        ),
                      ),
                  ],
                ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24)),
      ]),
    );
  }
}
