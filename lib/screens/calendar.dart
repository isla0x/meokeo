import 'package:flutter/cupertino.dart';

import '../holidays.dart';
import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'invite.dart';
import 'photo_viewer.dart';
import 'room_create.dart';
import 'today.dart' show EmptyRooms;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month; // 보고 있는 달의 1일
  late DateTime _selected;
  String? _streamKey;
  Stream<List<Post>>? _stream;

  @override
  void initState() {
    super.initState();
    final t = now();
    _month = DateTime(t.year, t.month);
    _selected = DateTime(t.year, t.month, t.day);
  }

  Stream<List<Post>> _postsFor(AppState app, Room room) {
    final key = '${room.id}|${dayKey(_selected)}';
    if (key != _streamKey) {
      _streamKey = key;
      _stream = app.repo.postsOn(room.id, dayKey(_selected));
    }
    return _stream!;
  }

  bool get _atCurrentMonth {
    final t = now();
    return _month.year == t.year && _month.month == t.month;
  }

  void _goMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final t = now();
    if (next.isAfter(DateTime(t.year, t.month))) return;
    setState(() {
      _month = next;
      _selected = (next.year == t.year && next.month == t.month) ? DateTime(t.year, t.month, t.day) : next;
    });
  }

  void _select(DateTime d, {required bool inMonth}) {
    setState(() {
      _selected = DateTime(d.year, d.month, d.day);
      if (!inMonth) _month = DateTime(d.year, d.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final room = app.current;

    final head = <Widget>[
      SizedBox(height: topPad(context)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 44,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GlassIconButton(
              icon: Ic.peopleDuo,
              label: '방 멤버 · 초대',
              onTap: () => room == null ? openRoomCreate(context) : openInvite(context, room),
            ),
          ]),
        ),
      ),
      const HeaderTitle(sub: '함께 먹은 기록', title: '캘린더'),
    ];

    Widget body;
    if (!app.roomsLoaded) {
      body = const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()));
    } else if (room == null) {
      body = const EmptyRooms();
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RoomSegments(
          labels: [for (final r in app.rooms) r.name],
          selected: app.currentIndex,
          onSelect: app.selectIndex,
          onAdd: app.rooms.length < kMaxRoomsPerUser ? () => openRoomCreate(context) : null,
        ),
        const SizedBox(height: 14),
        _MonthCard(
          room: room,
          month: _month,
          selected: _selected,
          canNext: !_atCurrentMonth,
          onPrev: () => _goMonth(-1),
          onNext: () => _goMonth(1),
          onSelect: _select,
        ),
        StreamBuilder<List<Post>>(
          stream: _postsFor(app, room),
          builder: (context, snap) {
            final posts = snap.data ?? const <Post>[];
            return FutureBuilder<Map<String, String>>(
              future: app.namesFor(room),
              builder: (context, ns) => _DayDetail(room: room, day: _selected, posts: posts, names: ns.data ?? const {}),
            );
          },
        ),
      ]);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ...head,
        body,
        const SizedBox(height: 130),
      ]),
    );
  }
}

// ───────────────────────── 달력 ─────────────────────────

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.room,
    required this.month,
    required this.selected,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final Room room;
  final DateTime month;
  final DateTime selected;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime d, {required bool inMonth}) onSelect;

  @override
  Widget build(BuildContext context) {
    final today = now();
    final todayKey = dayKey(today);
    final selKey = dayKey(selected);

    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7; // 일요일 = 0
    final daysIn = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((lead + daysIn) / 7).ceil();

    Widget cell(DateTime d) {
      final inMonth = d.month == month.month;
      final key = dayKey(d);
      final meals = inMonth ? (room.dots[key] ?? const <String>[]) : const <String>[];
      final isToday = key == todayKey;
      final isSel = key == selKey;
      final Color numColor = !inMonth
          ? C.grayC7
          : isSel
              ? C.sub
              : isToday
                  ? C.ink6
                  : isRedDay(d)
                      ? C.red
                      : C.black;
      final dots = <Widget>[];
      for (final m in Meal.values) {
        if (!meals.contains(m.name)) continue;
        if (dots.isNotEmpty) dots.add(const SizedBox(width: 3));
        dots.add(Container(width: 5, height: 5, decoration: BoxDecoration(color: m.color, shape: BoxShape.circle)));
      }
      final label = '${d.month}월 ${d.day}일${isSel ? ', 선택됨' : isToday ? ', 오늘' : dots.isNotEmpty ? ', 기록 있음' : ''}';
      return Expanded(
        child: Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(d, inMonth: inMonth),
            child: SizedBox(
              height: 44,
              child: Column(children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isToday ? C.track : null,
                    shape: BoxShape.circle,
                    border: isSel ? Border.all(color: C.grayC7, width: 1.5) : null,
                  ),
                  child: Text(
                    '${d.day}',
                    style: ts(15, w: (isSel || isToday) ? FontWeight.w700 : FontWeight.w400, lh: 20, color: numColor),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(height: 5, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: dots)),
              ]),
            ),
          ),
        ),
      );
    }

    final weekRows = <Widget>[];
    for (var r = 0; r < rows; r++) {
      weekRows.add(Row(children: [
        for (var c = 0; c < 7; c++) cell(DateTime(month.year, month.month, 1 + r * 7 + c - lead)),
      ]));
    }

    Widget arrow(IconSpec icon, String label, VoidCallback? onTap) => Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(child: Opacity(opacity: onTap == null ? 0.3 : 1, child: MIcon(icon, size: 20))),
            ),
          ),
        );

    return CardBox(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(children: [
        SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Row(children: [
              Text('${month.year}년 ${month.month}월', style: ts(18, w: FontWeight.w700, lh: 22)),
              const Spacer(),
              arrow(Ic.chevLeftGray, '이전 달', onPrev),
              arrow(Ic.chevRightGray, '다음 달', canNext ? onNext : null),
            ]),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 18,
          child: Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Text(
                  const ['일', '월', '화', '수', '목', '금', '토'][i],
                  textAlign: TextAlign.center,
                  style: ts(12, lh: 18, color: i == 0 ? C.red : C.sub),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        ...weekRows,
      ]),
    );
  }
}

// ───────────────────────── 고른 날 ─────────────────────────

class _DayDetail extends StatelessWidget {
  const _DayDetail({required this.room, required this.day, required this.posts, required this.names});
  final Room room;
  final DateTime day;
  final List<Post> posts;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.uid;
    final order = room.membersFor(me);
    String nameOf(String u) => u == me ? '나' : (names[u] ?? '…');
    Post? find(Meal m, String u) {
      for (final p in posts) {
        if (p.meal == m && p.uid == u) return p;
      }
      return null;
    }

    Widget tile(Meal m, String u) {
      final p = find(m, u);
      if (p == null) {
        return Semantics(label: '${nameOf(u)} 안 올림', child: const SizedBox(width: 44, height: 44, child: EmptyTile(radius: 11, dashWidth: 12)));
      }
      return Semantics(
        button: true,
        label: '${nameOf(u)} ${m.label} 사진',
        child: GestureDetector(
          onTap: () => openPhoto(context, room, p, nameOf(u), u == me),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(11)),
              boxShadow: [BoxShadow(color: Color(0x14000000), spreadRadius: 0.5)],
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(11), child: PhotoFill(p.image)),
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text('${day.month}월 ${day.day}일 ${kWeekdayKo[day.weekday - 1]}요일', style: ts(15, w: FontWeight.w600, lh: 20)),
          const Spacer(),
          if (posts.isNotEmpty) Text('${posts.length}장', style: ts(12, lh: 16, color: C.sub)),
        ]),
      ),
      CardBox(
        clip: true,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
            child: Row(children: [
              const SizedBox(width: 62),
              Expanded(
                child: Row(children: [
                  for (var i = 0; i < kMaxMembers; i++)
                    Expanded(
                      child: i < order.length
                          ? Text(nameOf(order[i]), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: ts(12, lh: 16, color: C.sub))
                          : const SizedBox.shrink(),
                    ),
                ]),
              ),
            ]),
          ),
          for (final m in Meal.values)
            Container(
              height: 56,
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.sep, width: 0.5))),
              child: Row(children: [
                SizedBox(
                  width: 62,
                  child: Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: m.color, borderRadius: BorderRadius.circular(7)),
                      alignment: Alignment.center,
                      child: MIcon(m.glyph, size: 15),
                    ),
                    const SizedBox(width: 5),
                    Text(m.label, style: ts(15, w: FontWeight.w600, lh: 20)),
                  ]),
                ),
                Expanded(
                  child: Row(children: [
                    for (var i = 0; i < kMaxMembers; i++)
                      Expanded(child: Center(child: i < order.length ? tile(m, order[i]) : const SizedBox.shrink())),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    ];
  }
}
