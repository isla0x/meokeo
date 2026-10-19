import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'posts.dart';

/// 끼니별 알림 설정 (켜짐 여부 + 시각)
class MealAlarm {
  MealAlarm({required this.enabled, required this.hour, required this.minute});
  bool enabled;
  int hour;
  int minute;
}

const Map<Meal, List<int>> _defaultTimes = {
  Meal.breakfast: [8, 30],
  Meal.lunch: [12, 30],
  Meal.dinner: [19, 0],
};

const Map<Meal, String> _bodies = {
  Meal.breakfast: '아침은 뭐 먹었어? 방 친구들에게 사진을 올려 봐요 🌅',
  Meal.lunch: '점심은 뭐 먹었어? 방 친구들에게 사진을 올려 봐요 ☀️',
  Meal.dinner: '저녁은 뭐 먹었어? 방 친구들에게 사진을 올려 봐요 🌙',
};

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
    await init();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true, badge: false) ?? false;
  }

  Future<Map<Meal, MealAlarm>> load() async {
    final sp = await SharedPreferences.getInstance();
    return {
      for (final m in Meal.values)
        m: MealAlarm(
          enabled: sp.getBool('alarm_${m.name}_on') ?? false,
          hour: sp.getInt('alarm_${m.name}_h') ?? _defaultTimes[m]![0],
          minute: sp.getInt('alarm_${m.name}_m') ?? _defaultTimes[m]![1],
        ),
    };
  }

  Future<void> save(Map<Meal, MealAlarm> alarms) async {
    final sp = await SharedPreferences.getInstance();
    for (final e in alarms.entries) {
      await sp.setBool('alarm_${e.key.name}_on', e.value.enabled);
      await sp.setInt('alarm_${e.key.name}_h', e.value.hour);
      await sp.setInt('alarm_${e.key.name}_m', e.value.minute);
    }
    await _schedule(alarms);
  }

  /// 앱을 켤 때 저장된 설정대로 다시 예약해요.
  Future<void> restore() async {
    await init();
    await _schedule(await load());
  }

  Future<void> _schedule(Map<Meal, MealAlarm> alarms) async {
    await init();
    await _plugin.cancelAll();
    for (final e in alarms.entries) {
      if (!e.value.enabled) continue;
      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, e.value.hour, e.value.minute);
      if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        e.key.index + 1,
        '뭐먹어? ${e.key.emoji}',
        _bodies[e.key]!,
        when,
        const NotificationDetails(
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
