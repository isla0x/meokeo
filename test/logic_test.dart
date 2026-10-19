import 'package:flutter_test/flutter_test.dart';
import 'package:meokeo/holidays.dart';
import 'package:meokeo/models.dart';
import 'package:meokeo/screens/join_room.dart';

void main() {
  test('끼니 시간 글자', () {
    expect(Meal.breakfast.window(), '오전 7:00 – 9:30');
    expect(Meal.lunch.window(), '오전 11:30 – 오후 1:00');
    expect(Meal.dinner.window(), '오후 5:00 – 7:00');
    expect(Meal.lunch.window(spaced: false), '오전 11:30–오후 1:00');
    expect(clockKoMin(8 * 60), '오전 8:00');
    expect(clockKoMin(12 * 60), '오후 12:00');
    expect(clockKoMin(0), '오전 12:00');
  });

  test('지금 시각의 끼니', () {
    Meal? at(int h, int m) => Meal.forPost(DateTime(2026, 10, 19, h, m));
    expect(at(6, 59), isNull);
    expect(at(7, 0), Meal.breakfast);
    expect(at(10, 30), Meal.breakfast); // 아침 마감 뒤, 점심 전
    expect(at(12, 31), Meal.lunch);
    expect(at(15, 0), Meal.lunch);
    expect(at(17, 0), Meal.dinner);
    expect(at(23, 50), Meal.dinner);
    expect(Meal.lunch.phase(DateTime(2026, 10, 19, 12, 31)), MealPhase.now);
    expect(Meal.breakfast.phase(DateTime(2026, 10, 19, 12, 31)), MealPhase.past);
    expect(Meal.dinner.phase(DateTime(2026, 10, 19, 12, 31)), MealPhase.upcoming);
  });

  test('초대 코드 정리', () {
    expect(CodeFormatter.clean('k7m2-9qx4'), 'K7M29QX4');
    expect(CodeFormatter.clean(' K7M2 9QX4 zzz '), 'K7M29QX4');
    expect(CodeFormatter.clean('한글!?'), '');
    final r = Room(id: 'r', name: 'n', icon: RoomIcon.dining, ownerId: 'a', members: ['a'], code: 'K7M29QX4');
    expect(r.codeSpaced, 'K7M2-9QX4');
  });

  test('방 구성원은 나를 맨 앞에', () {
    final r = Room(id: 'r', name: 'n', icon: RoomIcon.heart, ownerId: 'a', members: ['a', 'b', 'c'], code: 'AAAAAAAA');
    expect(r.membersFor('c'), ['c', 'a', 'b']);
    expect(r.isFull, isFalse);
  });

  test('날짜 글자와 빨간 날', () {
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    expect(isRedDay(DateTime(2026, 10, 18)), isTrue); // 일요일
    expect(isRedDay(DateTime(2026, 10, 9)), isTrue); // 한글날
    expect(isRedDay(DateTime(2026, 10, 10)), isFalse); // 토요일
  });
}
