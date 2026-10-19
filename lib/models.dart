import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import 'icons.dart';
import 'theme.dart';

/// 화면에서 "지금"을 읽는 곳. 테스트에서는 고정된 시각으로 바꿔요.
DateTime Function() nowProvider = DateTime.now;
DateTime now() => nowProvider();

const int kMaxMembers = 4;
const int kMaxRoomsPerUser = 3;
const int kCodeLength = 8;

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const List<String> kWeekdayKo = ['월', '화', '수', '목', '금', '토', '일'];

/// 12시간제 한글 시각: 오전 8:00
String clockKo(int hour, int minute) {
  final per = hour < 12 ? '오전' : '오후';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$per $h12:${minute.toString().padLeft(2, '0')}';
}

String clockKoMin(int minutes) => clockKo(minutes ~/ 60, minutes % 60);

enum MealPhase { upcoming, now, past }

enum Meal {
  breakfast('아침', 7 * 60, 9 * 60 + 30),
  lunch('점심', 11 * 60 + 30, 13 * 60),
  dinner('저녁', 17 * 60, 19 * 60);

  const Meal(this.label, this.startMin, this.endMin);

  final String label;
  final int startMin; // 올릴 수 있는 시간 시작
  final int endMin; // 마감

  Color get color => switch (this) {
        Meal.breakfast => C.accent,
        Meal.lunch => C.accent,
        Meal.dinner => C.accent,
      };

  IconSpec get glyph => switch (this) {
        Meal.breakfast => Ic.sunrise,
        Meal.lunch => Ic.sun,
        Meal.dinner => Ic.moon,
      };

  /// 알림 시각의 처음 값
  int get defaultAlarmMin => switch (this) {
        Meal.breakfast => 8 * 60,
        Meal.lunch => 12 * 60,
        Meal.dinner => 18 * 60,
      };

  /// "오전 7:00 – 9:30" (오늘 화면) / "오전 7:00–9:30" (알림 화면)
  String window({bool spaced = true}) {
    final samePeriod = (startMin ~/ 60 < 12) == (endMin ~/ 60 < 12);
    final a = clockKoMin(startMin);
    final b = samePeriod
        ? clockKoMin(endMin).split(' ').last
        : clockKoMin(endMin);
    return spaced ? '$a – $b' : '$a–$b';
  }

  MealPhase phase(DateTime t) {
    final m = t.hour * 60 + t.minute;
    if (m < startMin) return MealPhase.upcoming;
    if (m < endMin) return MealPhase.now;
    return MealPhase.past;
  }

  /// 카메라 버튼으로 올릴 때의 끼니: 지금 열린 끼니, 없으면 가장 최근에 시작한 끼니. 아침 전이면 없음.
  static Meal? forPost(DateTime t) {
    Meal? pick;
    for (final m in Meal.values) {
      if (m.phase(t) != MealPhase.upcoming) pick = m;
    }
    return pick;
  }
}

enum RoomIcon {
  heart('heart', C.pink),
  house('home', C.orange),
  people('people', C.blue),
  dining('dining', C.accent);

  const RoomIcon(this.key, this.color);
  final String key;
  final Color color;

  static RoomIcon parse(String? key) =>
      RoomIcon.values.firstWhere((e) => e.key == key, orElse: () => RoomIcon.dining);

  String get label => switch (this) {
        RoomIcon.heart => '하트',
        RoomIcon.house => '집',
        RoomIcon.people => '사람들',
        RoomIcon.dining => '포크와 숟가락',
      };
}

class Room {
  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.ownerId,
    required this.members,
    required this.code,
    this.dots = const {},
    this.createdAt,
  });

  final String id;
  final String name;
  final RoomIcon icon;
  final String ownerId;
  final List<String> members;
  final String code;

  /// 날짜(2026-10-19) → 그날 누군가 올린 끼니들. 캘린더의 점이에요.
  final Map<String, List<String>> dots;

  final DateTime? createdAt;

  bool get isFull => members.length >= kMaxMembers;

  /// 나를 맨 앞에 둔 구성원 목록
  List<String> membersFor(String myUid) =>
      [myUid, ...members.where((m) => m != myUid)];

  /// "K7M2-9QX4"
  String get codeSpaced =>
      code.length == kCodeLength ? '${code.substring(0, 4)}-${code.substring(4)}' : code;
}

class Post {
  Post({
    required this.id,
    required this.uid,
    required this.meal,
    required this.date,
    required this.photo,
    required this.text,
    required this.at,
  });

  final String id;
  final String uid;
  final Meal meal;
  final String date;
  final Uint8List photo;
  final String text;
  final DateTime at;

  late final ImageProvider image = MemoryImage(photo);

  String get timeLabel =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}

class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
