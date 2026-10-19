import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// 알림 설정: 끼니별 켜짐/시각 + 마감 30분 전 + 방 사람이 올렸을 때
class NotifSettings {
  NotifSettings({
    required this.on,
    required this.minutes,
    this.deadline = true,
    this.peer = false,
  });

  final Map<Meal, bool> on;
  final Map<Meal, int> minutes; // 하루 중 몇 분 (예: 12:00 → 720)
  bool deadline;
  bool peer;

  factory NotifSettings.defaults() => NotifSettings(
        on: {for (final m in Meal.values) m: true},
        minutes: {for (final m in Meal.values) m: m.defaultAlarmMin},
      );

  NotifSettings copy() => NotifSettings(
        on: Map.of(on),
        minutes: Map.of(minutes),
        deadline: deadline,
        peer: peer,
      );
}

const _details = NotificationDetails(
  iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
);

class Notifier {
  Notifier._();
  static final instance = Notifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }
    await _plugin.initialize(const InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  Future<bool> requestPermission() async {
    try {
      await init();
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true, badge: false) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ───────── 저장 ─────────
  Future<NotifSettings> load() async {
    final sp = await SharedPreferences.getInstance();
    final s = NotifSettings.defaults();
    for (final m in Meal.values) {
      s.on[m] = sp.getBool('alarm_${m.name}_on') ?? true;
      s.minutes[m] = sp.getInt('alarm_${m.name}_min') ?? m.defaultAlarmMin;
    }
    s.deadline = sp.getBool('alarm_deadline') ?? true;
    s.peer = sp.getBool('alarm_peer') ?? false;
    return s;
  }

  Future<void> save(NotifSettings s) async {
    final sp = await SharedPreferences.getInstance();
    for (final m in Meal.values) {
      await sp.setBool('alarm_${m.name}_on', s.on[m] ?? true);
      await sp.setInt('alarm_${m.name}_min', s.minutes[m] ?? m.defaultAlarmMin);
    }
    await sp.setBool('alarm_deadline', s.deadline);
    await sp.setBool('alarm_peer', s.peer);
    await reschedule(s);
  }

  // ───────── "이미 올렸어요" 기록 (마감 알림에서 빼려고) ─────────
  Future<void> markPosted(DateTime day, Meal meal) async {
    final sp = await SharedPreferences.getInstance();
    final keys = sp.getStringList('posted_keys') ?? <String>[];
    final k = '${dayKey(day)}_${meal.name}';
    if (!keys.contains(k)) {
      keys.add(k);
      // 오래된 기록은 정리 (최근 40개만)
      final trimmed = keys.length > 40 ? keys.sublist(keys.length - 40) : keys;
      await sp.setStringList('posted_keys', trimmed);
    }
    await reschedule(await load());
  }

  Future<Set<String>> _posted() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getStringList('posted_keys') ?? const <String>[]).toSet();
  }

  /// 앱을 켤 때 저장된 설정대로 다시 예약해요.
  Future<void> restore() async {
    try {
      await reschedule(await load());
    } catch (_) {}
  }

  Future<void> reschedule(NotifSettings s) async {
    try {
      await init();
      await _plugin.cancelAll();
      final nowT = tz.TZDateTime.now(tz.local);
      final posted = await _posted();

      for (final m in Meal.values) {
        // 1) 식사 알림: 매일 같은 시각
        if (s.on[m] ?? true) {
          final min = s.minutes[m] ?? m.defaultAlarmMin;
          var when = tz.TZDateTime(tz.local, nowT.year, nowT.month, nowT.day, min ~/ 60, min % 60);
          if (!when.isAfter(nowT)) when = when.add(const Duration(days: 1));
          await _plugin.zonedSchedule(
            m.index + 1,
            '냠냠 시간',
            '${m.label} 뭐먹어요?',
            when,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }

        // 2) 마감 30분 전: 앞으로 7일, 이미 올린 끼니는 빼요
        if (s.deadline) {
          for (var d = 0; d < 7; d++) {
            final day = nowT.add(Duration(days: d));
            if (posted.contains('${dayKey(day)}_${m.name}')) continue;
            final at = m.endMin - 30;
            final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, at ~/ 60, at % 60);
            if (!when.isAfter(nowT)) continue;
            await _plugin.zonedSchedule(
              100 + d * 3 + m.index,
              '마감 30분 전',
              '아직 ${m.label}을 안 올렸어요',
              when,
              _details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }
      }
    } catch (_) {
      // 알림은 부가 기능이라, 실패해도 앱은 계속 써요.
    }
  }

  /// 앱을 쓰는 중에 방 사람이 올렸을 때 바로 띄우는 알림
  Future<void> showNow(String title, String body) async {
    try {
      await init();
      await _plugin.show(900 + DateTime.now().millisecond % 90, title, body, _details);
    } catch (_) {}
  }
}
