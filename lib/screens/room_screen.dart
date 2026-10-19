import 'package:flutter/material.dart';

import '../data.dart';
import '../posts.dart';
import '../theme.dart';
import 'calendar.dart';
import 'invite.dart';
import 'post_sheet.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final DateTime _today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room?>(
      stream: Repo.instance.room(widget.roomId),
      builder: (context, rs) {
        final room = rs.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(room == null ? '' : '${room.icon} ${room.name}'),
            actions: [
              IconButton(
                tooltip: '달력',
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: room == null
                    ? null
                    : () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => CalendarScreen(room: room))),
              ),
              IconButton(
                tooltip: '초대·멤버',
                icon: const Icon(Icons.group_add_outlined),
                onPressed: room == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => InviteScreen(roomId: room.id))),
              ),
            ],
          ),
          body: room == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Post>>(
                  stream: PostRepo.instance.postsOn(room.id, dayKey(_today)),
                  builder: (context, ps) {
                    if (ps.hasError) {
                      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('불러오지 못했어요.\n(${errorDetail(ps.error!)})', textAlign: TextAlign.center)));
                    }
                    final posts = ps.data ?? const <Post>[];
                    return FutureBuilder<Map<String, String>>(
                      future: Repo.instance.nicknames(room.members),
                      builder: (context, ns) {
                        final names = ns.data ?? const <String, String>{};
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('${_today.month}월 ${_today.day}일 오늘 뭐먹었어?',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            ),
                            for (final meal in Meal.values)
                              _MealSection(
                                room: room,
                                meal: meal,
                                day: _today,
                                posts: posts.where((p) => p.meal == meal).toList(),
                                names: names,
                              ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text('사진은 폰 앨범에는 저장되지 않아요',
                                  style: TextStyle(color: kMuted, fontSize: 13)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.room,
    required this.meal,
    required this.day,
    required this.posts,
    required this.names,
  });

  final Room room;
  final Meal meal;
  final DateTime day;
  final List<Post> posts;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final mine = posts.any((p) => p.uid == Repo.instance.uid);
    final waiting = room.members.where((m) => !posts.any((p) => p.uid == m)).toList();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${meal.emoji} ${meal.label}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(meal.window, style: const TextStyle(color: kMuted, fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () => showPostSheet(context, room: room, meal: meal, day: day),
                child: Text(mine ? '다시 올리기' : '올리기'),
              ),
            ],
          ),
          if (posts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('아직 아무도 안 올렸어요', style: TextStyle(color: kMuted)),
            )
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _PostCard(room: room, post: posts[i], names: names),
              ),
            ),
          if (posts.isNotEmpty && waiting.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '기다리는 중: ${waiting.map((m) => names[m] ?? '…').join(', ')}',
              style: const TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.room, required this.post, required this.names});
  final Room room;
  final Post post;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final isMe = post.uid == Repo.instance.uid;
    return GestureDetector(
      onLongPress: isMe
          ? () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('이 사진을 지울까요?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('지우기')),
                  ],
                ),
              );
              if (ok == true) await PostRepo.instance.delete(room.id, post);
            }
          : null,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 150,
                  child: Image.memory(
                    post.photo,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: kPinkSoft, child: Center(child: Text('🍽️'))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(isMe ? '나' : (names[post.uid] ?? '…'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (post.text.isNotEmpty)
              Text(post.text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
