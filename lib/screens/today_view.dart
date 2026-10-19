import 'package:flutter/material.dart';

import '../data.dart';
import '../posts.dart';
import '../theme.dart';
import 'post_sheet.dart';

class Member {
  Member(this.uid, this.name, this.index, this.isMe);
  final String uid;
  final String name;
  final int index;
  final bool isMe;
}

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class TodayView extends StatefulWidget {
  const TodayView({super.key, required this.room});
  final Room room;

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  late Future<Map<String, String>> _names = Repo.instance.nicknames(widget.room.members);

  @override
  void didUpdateWidget(covariant TodayView old) {
    super.didUpdateWidget(old);
    if (old.room.id != widget.room.id || old.room.members.length != widget.room.members.length) {
      _names = Repo.instance.nicknames(widget.room.members);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final now = DateTime.now();
    return StreamBuilder<List<Post>>(
      stream: PostRepo.instance.postsOn(room.id, dayKey(now)),
      builder: (context, ps) {
        if (ps.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('불러오지 못했어요.\n(${errorDetail(ps.error!)})', textAlign: TextAlign.center),
            ),
          );
        }
        final posts = ps.data ?? const <Post>[];
        return FutureBuilder<Map<String, String>>(
          future: _names,
          builder: (context, ns) {
            final names = ns.data ?? const <String, String>{};
            final me = Repo.instance.uid;
            final order = [me, ...room.members.where((m) => m != me)];
            final members = [
              for (var i = 0; i < order.length; i++)
                Member(order[i], order[i] == me ? '나' : (names[order[i]] ?? '…'), i, order[i] == me),
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
              children: [
                for (final meal in Meal.values)
                  _MealSection(
                    room: room,
                    meal: meal,
                    now: now,
                    members: members,
                    posts: posts.where((p) => p.meal == meal).toList(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MealHeader extends StatelessWidget {
  const _MealHeader({required this.meal, required this.phase});
  final Meal meal;
  final MealPhase phase;

  @override
  Widget build(BuildContext context) {
    final current = phase == MealPhase.now;
    return Row(children: [
      Container(
        width: current ? 30 : 26,
        height: current ? 30 : 26,
        decoration: BoxDecoration(color: meal.color, borderRadius: BorderRadius.circular(8)),
        child: Icon(meal.icon, color: Colors.white, size: current ? 18 : 16),
      ),
      const SizedBox(width: 8),
      Text(meal.label,
          style: TextStyle(fontSize: current ? 20 : 17, fontWeight: FontWeight.w800)),
      if (current) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFFE2E2E9), borderRadius: BorderRadius.circular(10)),
          child: const Text('지금', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
        ),
      ],
      const Spacer(),
      Text(meal.window, style: const TextStyle(fontSize: 13, color: kMuted)),
    ]);
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.room,
    required this.meal,
    required this.now,
    required this.members,
    required this.posts,
  });
  final Room room;
  final Meal meal;
  final DateTime now;
  final List<Member> members;
  final List<Post> posts;

  void _post(BuildContext context) =>
      showPostSheet(context, room: room, meal: meal, day: now);

  @override
  Widget build(BuildContext context) {
    final phase = meal.phase(now);
    if (phase == MealPhase.upcoming) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(kRadius), boxShadow: softShadow()),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: meal.color, borderRadius: BorderRadius.circular(8)),
            child: Icon(meal.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(meal.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFFA0A0A5)),
          const Spacer(),
          Text(meal.window, style: const TextStyle(fontSize: 13, color: kMuted)),
        ]),
      );
    }

    final byUid = {for (final p in posts) p.uid: p};
    final posted = members.where((m) => byUid.containsKey(m.uid)).length;
    final iPosted = byUid.containsKey(Repo.instance.uid);
    final current = phase == MealPhase.now;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: _MealHeader(meal: meal, phase: phase),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(kRadius), boxShadow: softShadow()),
          clipBehavior: Clip.antiAlias,
          child: current
              ? _BigGrid(room: room, members: members, byUid: byUid, onPost: () => _post(context), posted: posted, iPosted: iPosted)
              : _CompactRow(room: room, members: members, byUid: byUid, onPost: () => _post(context)),
        ),
        if (current)
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, size: 13, color: kMuted),
              SizedBox(width: 5),
              Text('앨범에는 저장되지 않아요', style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
          ),
      ]),
    );
  }
}

// ───────── 지금 끼니: 큰 사진 칸 ─────────
class _BigGrid extends StatelessWidget {
  const _BigGrid({
    required this.room,
    required this.members,
    required this.byUid,
    required this.onPost,
    required this.posted,
    required this.iPosted,
  });
  final Room room;
  final List<Member> members;
  final Map<String, Post> byUid;
  final VoidCallback onPost;
  final int posted;
  final bool iPosted;

  @override
  Widget build(BuildContext context) {
    final rows = <List<Member>>[];
    for (var i = 0; i < members.length; i += 2) {
      rows.add(members.sublist(i, i + 2 > members.length ? members.length : i + 2));
    }
    final remaining = members.length - posted;
    final rest = remaining == 0
        ? ' · 모두 올렸어요'
        : (remaining == 1 && !iPosted ? ' · 나만 남았어요' : ' · $remaining명 남았어요');
    return Column(children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: SizedBox(
            height: 106,
            child: Row(children: [
              for (var i = 0; i < r.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(child: PhotoTile(room: room, member: r[i], post: byUid[r[i].uid], onPost: onPost)),
              ],
            ]),
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(children: [
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$posted명이 올렸어요', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              TextSpan(text: rest, style: const TextStyle(color: kMuted, fontSize: 15)),
            ])),
          ),
          for (final m in members)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: byUid.containsKey(m.uid) ? kTeal : Colors.transparent,
                border: Border.all(color: byUid.containsKey(m.uid) ? kTeal : const Color(0xFFC7C7CC), width: 1),
              ),
            ),
        ]),
      ),
    ]);
  }
}

// ───────── 지난 끼니: 작은 사진 한 줄 ─────────
class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.room, required this.members, required this.byUid, required this.onPost});
  final Room room;
  final List<Member> members;
  final Map<String, Post> byUid;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        for (var i = 0; i < kMaxMembers; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: i >= members.length
                ? const SizedBox.shrink()
                : Column(children: [
                    SizedBox(
                      height: 54,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PhotoTile(
                          room: room,
                          member: members[i],
                          post: byUid[members[i].uid],
                          onPost: onPost,
                          compact: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(members[i].name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: kMuted)),
                  ]),
          ),
        ],
      ]),
    );
  }
}

class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.room,
    required this.member,
    required this.post,
    required this.onPost,
    this.compact = false,
  });
  final Room room;
  final Member member;
  final Post? post;
  final VoidCallback onPost;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = post;
    if (p == null) {
      // 아직 안 올림: 나는 카메라, 다른 사람은 "—"
      if (member.isMe) {
        return GestureDetector(
          onTap: onPost,
          child: Container(
            color: compact ? const Color(0xFFF2F2F7) : Colors.white,
            alignment: Alignment.center,
            child: Icon(Icons.photo_camera_rounded, color: kTeal, size: compact ? 20 : 30),
          ),
        );
      }
      return Container(
        color: const Color(0xFFF2F2F7),
        alignment: Alignment.center,
        child: const Text('—', style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 18)),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _Viewer(post: p, name: member.name))),
      onLongPress: member.isMe ? () => _confirmDelete(context, p) : null,
      child: Stack(fit: StackFit.expand, children: [
        Image.memory(p.photo, fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(color: kTealSoft)),
        if (!compact)
          Positioned(
            left: 8,
            bottom: 8,
            right: 8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(12)),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: member.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    if (p.text.isNotEmpty) TextSpan(text: '  ${p.text}', style: const TextStyle(fontSize: 12, color: kMuted)),
                    TextSpan(text: '  ${hm(p.at)}', style: const TextStyle(fontSize: 12, color: kMuted)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Post p) async {
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
    if (ok == true) await PostRepo.instance.delete(room.id, p);
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer({required this.post, required this.name});
  final Post post;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('$name · ${post.meal.label} ${hm(post.at)}', style: const TextStyle(fontSize: 15)),
      ),
      body: Column(children: [
        Expanded(child: InteractiveViewer(child: Center(child: Image.memory(post.photo)))),
        if (post.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(post.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }
}
