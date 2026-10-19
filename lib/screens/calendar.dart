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
          backgroundColor: CupertinoColors.white,
          child: CustomScrollView(slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('캘린더'),
              trailing: NavActions(model: model),
              backgroundColor: CupertinoColors.white,
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
        Set<Meal> mealsOf(DateTime d) => {for (final p in byDay[dayKey(d)] ?? const <Post>[]) p.meal};

        final selectedKey = dayKey(_selected);
        final dayPosts = byDay[selectedKey] ?? const <Post>[];
        final header = '${_selected.month}월 ${_selected.day}일 ${kWeekdays[_selected.weekday - 1]}요일';

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(children: [
              Expanded(
                child: Text('${_month.year}년 ${_month.month}월',
                    style: font(18, FontWeight.w700, letterSpacing: -0.3).copyWith(color: label)),
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
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
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
                          meals: inMonth ? mealsOf(date) : const <Meal>{},
                          onTap: () => setState(() => _selected = date),
                        );
                      }),
                  ]),
              ]),
            ),
          ),
          if (dayPosts.isEmpty)
            Section(
              headerText: header,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Text('이 날은 올린 사진이 없어요', style: font(13, FontWeight.w400).copyWith(color: secondary))),
                ),
              ],
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
                          Text('$header · ${meal.label}', style: font(15, FontWeight.w700)),
                        ]),
                        children: [
                          MealTiles(
                            room: widget.room,
                            meal: meal,
                            onPost: () => showPostSheet(context, room: widget.room, meal: meal, day: _selected),
                            entries: [
                              for (final p in dayPosts.where((p) => p.meal == meal))
                                TileEntry(
                                  members.firstWhere((m) => m.uid == p.uid,
                                      orElse: () => Member(p.uid, '…', 0, p.uid == Repo.instance.uid)),
                                  p,
                                ),
                            ],
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
    required this.meals,
    required this.onTap,
  });
  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final Set<Meal> meals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    var numberColor = !inMonth
        ? const Color(0xFFC8CADB)
        : date.weekday == DateTime.sunday
            ? CupertinoDynamicColor.resolve(kHolidayRed, context)
            : kInk;
    var weight = FontWeight.w500;
    Color? bg;
    if (isToday) {
      bg = kAccent;
      numberColor = CupertinoColors.white;
      weight = FontWeight.w700;
    } else if (isSelected) {
      bg = kAccentSoft.resolveFrom(context);
      numberColor = kIndigo;
      weight = FontWeight.w700;
    }
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Column(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: bg),
              child: Text('${date.day}', style: font(14, weight).copyWith(color: numberColor)),
            ),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final m in Meal.values)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: !inMonth ? null : (meals.contains(m) ? kMint : const Color(0xFFE3E5EF)),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
