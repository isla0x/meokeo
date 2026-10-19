// 앱스토어에 올릴 화면 사진(아이폰 6.3인치, 1206×2622)을 뽑아요.
// 평소 테스트에서는 건너뛰고, STORE_SHOTS=1 일 때만 돌아요.
// 저장 위치는 SHOT_DIR (없으면 build/shots).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meokeo/models.dart';
import 'package:meokeo/screens/invite.dart';
import 'package:meokeo/screens/notif_settings.dart';
import 'package:meokeo/screens/photo_viewer.dart';
import 'package:meokeo/screens/post_flow.dart';
import 'package:meokeo/screens/shell.dart';
import 'package:meokeo/widgets.dart';

import 'screens_test.dart' hide main;

final bool storeMode = Platform.environment['STORE_SHOTS'] == '1';

void main() {
  final skip = !storeMode;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadFonts();
  });

  setUp(() {
    nowProvider = () => DateTime(2026, 10, 19, 12, 31);
  });

  shotTest('스토어 1 · 오늘', (tester) async {
    await setup(tester, store: true);
    await launch(tester, demo(), select: 'friends');
    await shot(tester, 'store_1_today', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);

  shotTest('스토어 2 · 올리기', (tester) async {
    await setup(tester, store: true);
    await launch(tester, demo(), select: 'friends');
    await openSheet(
      tester,
      PostSheet(meal: Meal.lunch, auto: true, photo: food('kimchi'), takenAt: DateTime(2026, 10, 19, 12, 31), initialText: '김치찌개'),
    );
    await tester.tap(find.byType(MSwitch).at(1));
    await settle(tester);
    await shot(tester, 'store_2_post', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);

  shotTest('스토어 3 · 사진 크게', (tester) async {
    await setup(tester, store: true);
    final r = room('friends', '친구들', RoomIcon.people, four);
    final p = post('2026-10-19', Meal.lunch, 'doyun', 'katsu', text: '돈까스', h: 12, m: 4);
    await launch(tester, demo(), select: 'friends');
    final ctx = tester.element(find.byType(Shell));
    unawaited(openPhoto(ctx, r, p, '도윤', false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    await shot(tester, 'store_3_photo', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);

  shotTest('스토어 4 · 캘린더', (tester) async {
    await setup(tester, store: true);
    await launch(tester, demo(), home: const Shell(initialTab: 1), select: 'friends');
    await tester.tap(find.text('18'));
    await settle(tester);
    await shot(tester, 'store_4_calendar', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);

  shotTest('스토어 5 · 친구 초대', (tester) async {
    await setup(tester, store: true);
    final r = room('new', '회사 동기', RoomIcon.people, [me]);
    await launch(tester, demo(rooms: [r], posts: []), home: InvitePage(initial: r, created: true));
    await shot(tester, 'store_5_invite', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);

  shotTest('스토어 6 · 알림', (tester) async {
    await setup(tester, store: true);
    await launch(tester, demo(), home: const NotifSettingsPage());
    await shot(tester, 'store_6_notif', pixelRatio: 3);
    await finish(tester);
  }, skip: skip);
}
