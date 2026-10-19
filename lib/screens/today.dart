import 'package:flutter/cupertino.dart';

import '../data.dart';
import '../model.dart';
import '../posts.dart';
import '../ui.dart';
import 'join_room.dart';
import 'parts.dart';
import 'post_sheet.dart';
import 'room_create.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.model});
  final RoomsModel model;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final secondary = secondaryOf(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final room = model.current;
        return CupertinoPageScaffold(
          backgroundColor: CupertinoColors.systemGroupedBackground,
          child: CustomScrollView(slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('오늘'),
              trailing: NavActions(model: model),
              backgroundColor: CupertinoColors.systemGroupedBackground,
            ),
            SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                  child: Text('${now.month}월 ${now.day}일 ${kWeekdays[now.weekday - 1]}요일',
                      style: TextStyle(fontSize: 12, color: secondary)),
                ),
                RoomSwitcher(model: model),
                if (!model.loaded)
                  const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()))
                else if (model.error != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text('방을 불러오지 못했어요.\n(${errorDetail(model.error!)})', textAlign: TextAlign.center)),
                  )
                else if (room == null)
                  const _Empty()
                else
                  _RoomToday(key: ValueKey(room.id), room: room),
                const SizedBox(height: 24),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Center(
        child: Column(children: [
          Icon(CupertinoIcons.person_3_fill, size: 56, color: CupertinoColors.systemGrey3.resolveFrom(context)),
          const SizedBox(height: 14),
          const Text('아직 참여한 방이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('방을 만들거나, 친구가 보낸 코드로 들어와요.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: secondary)),
          const SizedBox(height: 22),
          PrimaryButton(
            label: '새 방 만들기',
            onPressed: () => Navigator.of(context)
                .push(CupertinoPageRoute(builder: (_) => const RoomCreateScreen(), fullscreenDialog: true)),
          ),
          CupertinoButton(
            onPressed: () => Navigator.of(context)
                .push(CupertinoPageRoute(builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
            child: const Text('코드로 참여하기'),
          ),
        ]),
      ),
    );
  }
}

class _RoomToday extends StatefulWidget {
  const _RoomToday({super.key, required this.room});
  final Room room;

  @override
  State<_RoomToday> createState() => _RoomTodayState();
}

class _RoomTodayState extends State<_RoomToday> {
  late final Stream<List<Post>> _posts =
      PostRepo.instance.postsOn(widget.room.id, dayKey(DateTime.now()));
  late Future<Map<String, String>> _names = Repo.instance.nicknames(widget.room.members);

  @override
  void didUpdateWidget(covariant _RoomToday old) {
    super.didUpdateWidget(old);
    if (old.room.members.length != widget.room.members.length) {
      _names = Repo.instance.nicknames(widget.room.members);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<List<Post>>(
      stream: _posts,
      builder: (context, ps) {
        if (ps.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: Text('불러오지 못했어요.\n(${errorDetail(ps.error!)})', textAlign: TextAlign.center)),
          );
        }
        final posts = ps.data ?? const <Post>[];
        return FutureBuilder<Map<String, String>>(
          future: _names,
          builder: (context, ns) {
            final members = buildMembers(widget.room, ns.data ?? const {});
            return Column(children: [
              for (final meal in Meal.values)
                _MealSection(
                  room: widget.room,
                  meal: meal,
                  now: now,
                  members: members,
                  posts: posts.where((p) => p.meal == meal).toList(),
                ),
            ]);
          },
        );
      },
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({required this.room, required this.meal, required this.now, required this.members, required this.posts});
  final Room room;
  final Meal meal;
  final DateTime now;
  final List<Member> members;
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    final phase = meal.phase(now);
    if (phase == MealPhase.upcoming) {
      return Section(
        header: mealHeader(context, meal, locked: true),
        children: [
          Row1(
            leading: Icon(CupertinoIcons.lock_fill, size: 18, color: secondaryOf(context)),
            title: '${meal.startLabel}에 열려요',
          ),
        ],
      );
    }

    final byUid = {for (final p in posts) p.uid: p};
    final posted = members.where((m) => byUid.containsKey(m.uid)).length;
    final iPosted = byUid.containsKey(Repo.instance.uid);
    final remaining = members.length - posted;
    var footer = '$posted명이 올렸어요';
    if (remaining == 0) {
      footer += ' · 모두 올렸어요';
    } else if (remaining == 1 && !iPosted) {
      footer += ' · 나만 남았어요';
    } else {
      footer += ' · $remaining명 남았어요';
    }
    if (phase == MealPhase.now) footer += '\n앨범에는 저장되지 않아요';

    return Section(
      header: mealHeader(context, meal, current: phase == MealPhase.now),
      indent: 82,
      footer: footer,
      children: [
        for (final m in members)
          PostRow(
            room: room,
            member: m,
            post: byUid[m.uid],
            onPost: () => showPostSheet(context, room: room, meal: meal, day: now),
          ),
      ],
    );
  }
}
