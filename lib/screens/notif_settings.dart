import 'package:flutter/material.dart';

import '../notifications.dart';
import '../posts.dart';
import '../theme.dart';

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('알림 권한이 꺼져 있어요. 설정 → 뭐먹어? → 알림에서 켜 주세요.')));
        }
        return;
      }
    }
    setState(() => a[m]!.enabled = on);
    await Notifier.instance.save(a);
  }

  Future<void> _pick(Meal m) async {
    final a = _alarms!;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: a[m]!.hour, minute: a[m]!.minute),
      helpText: '${m.label} 알림 시간',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (t == null) return;
    setState(() {
      a[m]!.hour = t.hour;
      a[m]!.minute = t.minute;
    });
    await Notifier.instance.save(a);
  }

  @override
  Widget build(BuildContext context) {
    final a = _alarms;
    return Scaffold(
      appBar: AppBar(title: const Text('알림 시간')),
      body: a == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text('정해진 시간에 "뭐 먹었어?" 알림이 와요.\n알림은 이 폰에서만 예약되고, 서버로 보내지 않아요.',
                      style: TextStyle(color: kMuted)),
                ),
                for (final m in Meal.values)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: Text(m.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_fmt(a[m]!)),
                      onTap: () => _pick(m),
                      trailing: Switch(
                        value: a[m]!.enabled,
                        activeColor: kPink,
                        onChanged: (v) => _toggle(m, v),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
