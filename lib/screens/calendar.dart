import 'package:flutter/cupertino.dart';

import '../data.dart';
import '../model.dart';
import '../posts.dart';
import '../ui.dart';
import 'parts.dart';
import 'post_sheet.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.model});
  final RoomsModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final room = model.current;
        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGroupedBackground,
          child: CustomScrollView(slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('캘린더'),
              trailing: NavActions(model: model),
              backgroundColor: CupertinoColors.systemGroupedBackground,
            ),
            SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                RoomSwitcher(model: model),
                if (!model.loaded)
                  const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()))
                else if (room == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
                    child: Center(
                      child: Text('방에 들어가면 지난 끼니를 달력에서 볼 수 있어요',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: secondaryOf(context))),
                    ),
                  )
                else
                  _RoomCalendar(key: ValueKey(room.id), room: room),
                const SizedBox(height: 24),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

enum _DayStatus { none, partial, all }

class _RoomCalendar extends StatefulWidget {
  const _RoomCalendar({super.key, required this.room});
  final Room room;

  @override
  State<_RoomCalendar> createState() => _RoomCalendarState();
}

class _RoomCalendarState extends State<_RoomCalendar> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = DateTime.now();
  late Stream<List<Post>> _stream = PostRepo.instance.postsInMonth(widget.room.id, _month);
  late Future<Map<String, String>> _names = Repo.instance.nicknames(widget.room.members);

  void _moveMonth(int d) {
    setState(() {
      _month = DateTime(_month.year, _month.month + d);
      final now = DateTime.now();
      _selected = (_month.year == now.year && _month.month == now.month) ? now : DateTime(_month.year, _month.month, 1);
      _stream = PostRepo.instance.postsInMonth(widget.room.id, _month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryOf(context);
    final label = labelOf(context);
    final today = dayKey(DateTime.now());
    final first = DateTime(_month.year, _month.month);
    final lead = first.weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final weeks = ((lead + daysInMonth) / 7).ceil();

    return StreamBuilder<List<Post>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('불러오지 못했어요.\n(${errorDetail(snap.error!)})', textAlign: TextAlign.center)),
          );
        }
        final posts = snap.data ?? const <Post>[];
        final byDay = <String, List<Post>>{};
        for (final p in posts) {
          byDay.putIfAbsent(p.date, () => []).add(p);
        }
        _DayStatus statusOf(DateTime d) {
          final list = byDay[dayKey(d)];
          if (list == null || list.isEmpty) return _DayStatus.none;
          return list.map((p) => p.meal).toSet().length == Meal.values.length ? _DayStatus.all : _DayStatus.partial;
        }

        final selectedKey = dayKey(_selected);
        final dayPosts = byDay[selectedKey] ?? const <Post>[];
        final header = '${_selected.month}월 ${_selected.day}일 ${kWeekdays[_selected.weekday - 1]}요일';

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(children: [
              Expanded(
                child: Text('${_month.year}년 ${_month.month}월',
                    style: font(17, FontWeight.w600, letterSpacing: -0.3).copyWith(color: label)),
              ),
              _MonthArrow(icon: CupertinoIcons.chevron_left, onTap: () => _moveMonth(-1)),
              _MonthArrow(icon: CupertinoIcons.chevron_right, onTap: () => _moveMonth(1)),
            ]),
          ),
          GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -300) {
                _moveMonth(1);
              } else if (v > 300) {
                _moveMonth(-1);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
              decoration: cardDecoration(context),
              child: Column(children: [
                SizedBox(
                  height: 22,
                  child: Row(children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Center(
                          child: Text(const ['일', '월', '화', '수', '목', '금', '토'][i],
                              style: font(11, FontWeight.w600).copyWith(
                                  color: i == 0 ? CupertinoDynamicColor.resolve(kHolidayRed, context) : secondary)),
                        ),
                      ),
                  ]),
                ),
                for (var w = 0; w < weeks; w++)
                  Row(children: [
                    for (var c = 0; c < 7; c++)
                      Builder(builder: (context) {
                        final date = DateTime(_month.year, _month.month, 1 - lead + w * 7 + c);
                        final inMonth = date.month == _month.month;
                        final key = dayKey(date);
                        return _DayCell(
                          date: date,
                          inMonth: inMonth,
                          isToday: key == today,
                          isSelected: key == selectedKey,
                          status: inMonth ? statusOf(date) : _DayStatus.none,
                          onTap: () => setState(() => _selected = date),
                        );
                      }),
                  ]),
              ]),
            ),
          ),
          if (dayPosts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 7),
                  child: Text(header, style: TextStyle(fontSize: 12, height: 16 / 12, color: secondary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('이 날은 올린 사진이 없어요', style: TextStyle(fontSize: 12, color: secondary))),
                ),
              ]),
            )
          else
            FutureBuilder<Map<String, String>>(
              future: _names,
              builder: (context, ns) {
                final members = buildMembers(widget.room, ns.data ?? const {});
                return Column(children: [
                  for (final meal in Meal.values)
                    if (dayPosts.any((p) => p.meal == meal))
                      Section(
                        header: Row(children: [
                          Icon(meal.icon, size: 13, color: meal.color),
                          const SizedBox(width: 5),
                          Text('$header · ${meal.label}', style: font(12, FontWeight.w600).copyWith(color: secondary)),
                        ]),
                        indent: 82,
                        children: [
                          for (final p in dayPosts.where((p) => p.meal == meal))
                            PostRow(
                              room: widget.room,
                              member: members.firstWhere((m) => m.uid == p.uid,
                                  orElse: () => Member(p.uid, '…', 0, p.uid == Repo.instance.uid)),
                              post: p,
                              onPost: () => showPostSheet(context, room: widget.room, meal: meal, day: _selected),
                            ),
                        ],
                      ),
                ]);
              },
            ),
        ]);
      },
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: kAccent)),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.status,
    required this.onTap,
  });
  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final _DayStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var numberColor = !inMonth
        ? secondaryOf(context)
        : date.weekday == DateTime.sunday
            ? CupertinoDynamicColor.resolve(kHolidayRed, context)
            : labelOf(context);
    var weight = FontWeight.w400;
    Color? circle;
    if (isToday) {
      circle = kAccent;
      numberColor = CupertinoColors.white;
      weight = FontWeight.w600;
    } else if (isSelected) {
      circle = CupertinoDynamicColor.resolve(kAccentSoft, context);
      numberColor = CupertinoDynamicColor.resolve(kAccentDeep, context);
      weight = FontWeight.w600;
    }
    final dot = switch (status) {
      _DayStatus.none => const SizedBox(width: 6, height: 6),
      _DayStatus.all => Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: kAccent)),
      _DayStatus.partial => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kAccent, width: 1.4)),
        ),
    };
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 46,
          child: Column(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: circle),
              child: Text('${date.day}', style: font(15, weight).copyWith(color: numberColor)),
            ),
            const SizedBox(height: 2),
            dot,
          ]),
        ),
      ),
    );
  }
}
