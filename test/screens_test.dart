// 화면 사진 뽑기: 각 화면을 목업과 같은 크기(390×844, 2배)로 그려서 PNG로 저장해요.
// 저장 위치는 환경변수 SHOT_DIR (없으면 build/shots).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meokeo/main.dart';
import 'package:meokeo/models.dart';
import 'package:meokeo/notifications.dart';
import 'package:meokeo/repo/demo_repo.dart';
import 'package:meokeo/screens/calendar.dart';
import 'package:meokeo/screens/invite.dart';
import 'package:meokeo/screens/join_room.dart';
import 'package:meokeo/screens/nickname.dart';
import 'package:meokeo/screens/notif_settings.dart';
import 'package:meokeo/screens/photo_viewer.dart';
import 'package:meokeo/screens/post_flow.dart';
import 'package:meokeo/screens/room_create.dart';
import 'package:meokeo/screens/shell.dart';
import 'package:meokeo/state.dart';
import 'package:meokeo/widgets.dart';

final String outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';
final GlobalKey shotKey = GlobalKey();

const me = 'me';
final Map<String, Uint8List> _foodCache = {};
Uint8List food(String n) => _foodCache.putIfAbsent(n, () => File('assets/illust/food_$n.jpg').readAsBytesSync());

Future<void> loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      final b = File('assets/fonts/$f').readAsBytesSync();
      l.addFont(Future.value(ByteData.sublistView(b)));
    }
    await l.load();
  }

  await load('PlusJakartaSans', [
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
  ]);
  await load('Pretendard', [
    'Pretendard-Regular.otf',
    'Pretendard-Medium.otf',
    'Pretendard-SemiBold.otf',
    'Pretendard-Bold.otf',
  ]);
}

Post post(String day, Meal meal, String uid, String f, {String text = '', int h = 12, int m = 0}) => Post(
      id: '${day}_${meal.name}_$uid',
      uid: uid,
      meal: meal,
      date: day,
      photo: food(f),
      text: text,
      at: DateTime(2026, 10, int.parse(day.substring(8)), h, m),
    );

Map<String, List<String>> calendarDots() {
  const b = 'breakfast', l = 'lunch', d = 'dinner';
  final spec = <int, List<String>>{
    1: [b, l, d], 2: [b], 3: [l, d], 4: [b, l], 5: [b, l, d], 7: [b, l, d], 8: [b, l, d], 9: [l, d],
    10: [b, l], 11: [b, l, d], 12: [l], 13: [b, d], 14: [b, l, d], 15: [l, d], 16: [b, l], 17: [b, l, d],
    18: [b, l, d], 19: [b, l],
  };
  return {for (final e in spec.entries) '2026-10-${e.key.toString().padLeft(2, '0')}': e.value};
}

Room room(String id, String name, RoomIcon icon, List<String> members, {Map<String, List<String>> dots = const {}}) =>
    Room(id: id, name: name, icon: icon, ownerId: me, members: members, code: 'K7M29QX4', dots: dots);

const four = [me, 'doyun', 'seoyeon', 'jihun'];

DemoRepo demo({List<Room>? rooms, List<Post>? posts}) => DemoRepo(
      myUid: me,
      nickname: '나',
      names: const {'doyun': '도윤', 'seoyeon': '서연', 'jihun': '지훈'},
      rooms: rooms ??
          [
            room('couple', '연인', RoomIcon.heart, [me, 'seoyeon']),
            room('family', '가족', RoomIcon.house, four),
            room('friends', '친구들', RoomIcon.people, four, dots: calendarDots()),
          ],
      posts: posts ?? _defaultPosts(),
    );

List<Post> _defaultPosts() => [
      // 오늘(19일)
      post('2026-10-19', Meal.breakfast, me, 'toast', h: 8, m: 2),
      post('2026-10-19', Meal.breakfast, 'doyun', 'cereal', h: 8, m: 20),
      post('2026-10-19', Meal.breakfast, 'seoyeon', 'yogurt', h: 8, m: 41),
      post('2026-10-19', Meal.lunch, 'doyun', 'katsu', h: 12, m: 4),
      post('2026-10-19', Meal.lunch, 'seoyeon', 'salad', h: 12, m: 9),
      post('2026-10-19', Meal.lunch, 'jihun', 'bibim', h: 12, m: 15),
      // 18일 (캘린더에서 고르는 날)
      post('2026-10-18', Meal.breakfast, me, 'yogurt'),
      post('2026-10-18', Meal.breakfast, 'doyun', 'toast'),
      post('2026-10-18', Meal.breakfast, 'jihun', 'cereal'),
      post('2026-10-18', Meal.lunch, me, 'bibim'),
      post('2026-10-18', Meal.lunch, 'doyun', 'katsu'),
      post('2026-10-18', Meal.lunch, 'seoyeon', 'salad'),
      post('2026-10-18', Meal.lunch, 'jihun', 'kimchi'),
      post('2026-10-18', Meal.dinner, me, 'katsu'),
      post('2026-10-18', Meal.dinner, 'doyun', 'salad'),
      post('2026-10-18', Meal.dinner, 'seoyeon', 'bibim'),
    ];

Future<void> setup(WidgetTester tester, {double keyboard = 0}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  const pad = FakeViewPadding(top: 94, bottom: 68);
  tester.view.padding = pad;
  tester.view.viewPadding = pad;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2);
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  debugDisableShadows = false;
  addTearDown(() {
    tester.view.reset();
    debugDefaultTargetPlatformOverride = null;
    nowProvider = DateTime.now;
  });
}

/// 앱을 띄우고(로그인까지) 첫 화면을 그려요.
Future<AppState> launch(WidgetTester tester, DemoRepo repo, {Widget? home, String? select}) async {
  final state = AppState(repo, useNotifications: false);
  await tester.runAsync(state.boot);
  if (select != null) state.select(select);
  await tester.pumpWidget(RepaintBoundary(key: shotKey, child: MeokeoApp(state: state, home: home ?? const Shell())));
  await settle(tester);
  return state;
}

Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> openSheet(WidgetTester tester, Widget sheet) async {
  final ctx = tester.element(find.byType(Shell));
  unawaited(showMSheet<void>(ctx, (_) => sheet));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await settle(tester);
}

Future<void> shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final img = await boundary.toImage(pixelRatio: 2);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    final f = File('$outDir/$name.png')..createSync(recursive: true);
    f.writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
  });

  setUp(() {
    nowProvider = () => DateTime(2026, 10, 19, 12, 31);
  });

  testWidgets('오늘 (점심 시간)', (tester) async {
    await setup(tester);
    await launch(tester, demo(), select: 'friends');
    await shot(tester, 'Today');
    await finish(tester);
  });

  testWidgets('오늘 (저녁 시간)', (tester) async {
    await setup(tester);
    nowProvider = () => DateTime(2026, 10, 19, 18, 10);
    await launch(tester, demo(), select: 'friends');
    await shot(tester, 'Today_dinner');
    await finish(tester);
  });

  testWidgets('오늘 (아침 전: 모두 잠김)', (tester) async {
    await setup(tester);
    nowProvider = () => DateTime(2026, 10, 19, 6, 30);
    await launch(tester, demo(posts: []), select: 'friends');
    await shot(tester, 'Today_early');
    await finish(tester);
  });

  testWidgets('오늘 (방 없음)', (tester) async {
    await setup(tester);
    await launch(tester, demo(rooms: [], posts: []));
    await shot(tester, 'Today_noroom');
    await finish(tester);
  });

  testWidgets('캘린더', (tester) async {
    await setup(tester);
    await launch(tester, demo(), home: const Shell(initialTab: 1), select: 'friends');
    await tester.tap(find.text('18'));
    await settle(tester);
    await shot(tester, 'Calendar');
    await finish(tester);
  });

  testWidgets('올리기 시트', (tester) async {
    await setup(tester);
    await launch(tester, demo(), select: 'friends');
    await openSheet(
      tester,
      PostSheet(meal: Meal.lunch, auto: true, photo: food('kimchi'), takenAt: DateTime(2026, 10, 19, 12, 31), initialText: '김치찌개'),
    );
    await tester.tap(find.byType(MSwitch).at(1)); // 가족 방은 끄기
    await settle(tester);
    await shot(tester, 'PostSheet');
    await finish(tester);
  });

  testWidgets('새 방 만들기 시트', (tester) async {
    await setup(tester);
    await launch(tester, demo(), select: 'friends');
    await openSheet(tester, const RoomCreateSheet(initialName: '회사 동기', initialIcon: RoomIcon.people));
    await shot(tester, 'RoomCreate');
    await finish(tester);
  });

  testWidgets('코드로 참여하기 시트', (tester) async {
    await setup(tester, keyboard: 296);
    await launch(tester, demo(), select: 'friends');
    await openSheet(tester, const JoinRoomSheet(initialCode: 'K7M29', autofocus: false));
    await shot(tester, 'JoinRoom');
    await finish(tester);
  });

  testWidgets('친구 초대하기', (tester) async {
    await setup(tester);
    final r = room('new', '회사 동기', RoomIcon.people, [me]);
    await launch(tester, demo(rooms: [r], posts: []), home: InvitePage(initial: r, created: true));
    await shot(tester, 'Invite');
    await finish(tester);
  });

  testWidgets('친구 초대하기 (4명 · 방장 아님)', (tester) async {
    await setup(tester);
    final r = Room(id: 'x', name: '친구들', icon: RoomIcon.heart, ownerId: 'doyun', members: four, code: 'K7M29QX4');
    await launch(tester, demo(rooms: [r], posts: []), home: InvitePage(initial: r));
    await shot(tester, 'Invite_full');
    await finish(tester);
  });

  testWidgets('알림 설정', (tester) async {
    await setup(tester);
    final state = await launch(tester, demo(), home: const NotifSettingsPage());
    expect(state.notif.on.values.every((v) => v), isTrue);
    await shot(tester, 'NotifSettings');
    await finish(tester);
  });

  testWidgets('이름 정하기', (tester) async {
    await setup(tester);
    await launch(tester, demo(), home: const NicknamePage());
    await shot(tester, 'Nickname');
    await finish(tester);
  });

  testWidgets('사진 크게 보기', (tester) async {
    await setup(tester);
    final r = room('friends', '친구들', RoomIcon.people, four);
    final p = post('2026-10-19', Meal.lunch, 'doyun', 'katsu', text: '돈까스', h: 12, m: 4);
    await launch(tester, demo(), select: 'friends');
    final ctx = tester.element(find.byType(Shell));
    unawaited(openPhoto(ctx, r, p, '도윤', false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    await shot(tester, 'PhotoViewer');
    await finish(tester);
  });

  testWidgets('알림 시각 기본값', (tester) async {
    final s = NotifSettings.defaults();
    expect(s.minutes[Meal.breakfast], 8 * 60);
    expect(s.minutes[Meal.lunch], 12 * 60);
    expect(s.minutes[Meal.dinner], 18 * 60);
    expect(s.deadline, isTrue);
    expect(s.peer, isFalse);
  });

  testWidgets('캘린더 화면이 그려진다', (tester) async {
    await setup(tester);
    await launch(tester, demo(), home: const CalendarPage(), select: 'friends');
    expect(find.text('2026년 10월'), findsOneWidget);
    await finish(tester);
  });
}
