import 'package:flutter/material.dart';

import '../data.dart';
import '../posts.dart';
import '../theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.room});
  final Room room;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = DateTime.now();

  void _move(int d) => setState(() {
        _month = DateTime(_month.year, _month.month + d);
        _selected = DateTime(_month.year, _month.month, 1);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.room.icon} ${widget.room.name} 달력')),
      body: StreamBuilder<List<Post>>(
        stream: PostRepo.instance.postsInMonth(widget.room.id, _month),
        builder: (context, snap) {
          final posts = snap.data ?? const <Post>[];
          final byDay = <String, List<Post>>{};
          for (final p in posts) {
            byDay.putIfAbsent(p.date, () => []).add(p);
          }
          final selPosts = (byDay[dayKey(_selected)] ?? [])
            ..sort((a, b) => a.meal.index.compareTo(b.meal.index));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left_rounded)),
                  Text('${_month.year}년 ${_month.month}월',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => _move(1), icon: const Icon(Icons.chevron_right_rounded)),
                ],
              ),
              Row(
                children: [
                  for (final w in const ['일', '월', '화', '수', '목', '금', '토'])
                    Expanded(
                      child: Center(
                          child: Text(w, style: const TextStyle(color: kMuted, fontSize: 12))),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              _grid(byDay),
              const SizedBox(height: 18),
              Text('${_selected.month}월 ${_selected.day}일',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (selPosts.isEmpty)
                const Text('이 날은 올린 사진이 없어요', style: TextStyle(color: kMuted))
              else
                FutureBuilder<Map<String, String>>(
                  future: Repo.instance.nicknames(widget.room.members),
                  builder: (context, ns) {
                    final names = ns.data ?? const <String, String>{};
                    return Column(
                      children: [
                        for (final p in selPosts)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(p.photo, width: 84, height: 84, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${p.meal.emoji} ${p.meal.label} · ${p.uid == Repo.instance.uid ? '나' : (names[p.uid] ?? '…')}',
                                          style: const TextStyle(fontWeight: FontWeight.w700)),
                                      if (p.text.isNotEmpty) Text(p.text),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _grid(Map<String, List<Post>> byDay) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7; // 일요일 시작
    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var d = 1; d <= days; d++) _cell(DateTime(_month.year, _month.month, d), byDay),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.85,
      children: cells,
    );
  }

  Widget _cell(DateTime d, Map<String, List<Post>> byDay) {
    final posts = byDay[dayKey(d)] ?? const <Post>[];
    final sel = dayKey(d) == dayKey(_selected);
    final today = dayKey(d) == dayKey(DateTime.now());
    return GestureDetector(
      onTap: () => setState(() => _selected = d),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: sel ? kPinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: today ? kPink : Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${d.day}', style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final m in Meal.values)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: posts.any((p) => p.meal == m) ? kPink : const Color(0xFFE6E6EA),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
