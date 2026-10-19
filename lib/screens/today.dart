import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../icons.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'invite.dart';
import 'join_room.dart';
import 'notif_settings.dart';
import 'photo_viewer.dart';
import 'post_flow.dart';
import 'room_create.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  Timer? _tick;
  String? _streamKey;
  Stream<List<Post>>? _stream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  Stream<List<Post>> _postsFor(AppState app, Room room, DateTime t) {
    final key = '${room.id}|${dayKey(t)}';
    if (key != _streamKey) {
      _streamKey = key;
      _stream = app.repo.postsOn(room.id, dayKey(t));
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final room = app.current;
    final t = now();

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
            const SizedBox(width: 10),
            GlassIconButton(icon: Ic.bell, label: '알림 시간 설정', onTap: () => openNotifSettings(context)),
          ]),
        ),
      ),
      HeaderTitle(sub: '${t.month}월 ${t.day}일 ${kWeekdayKo[t.weekday - 1]}요일', title: '오늘'),
    ];

    Widget body;
    if (!app.roomsLoaded) {
      body = const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()));
    } else if (app.roomsError != null) {
      body = Padding(
        padding: const EdgeInsets.fromLTRB(36, 60, 36, 0),
        child: Text('방을 불러오지 못했어요.\n인터넷을 확인해 주세요.', textAlign: TextAlign.center, style: ts(15, lh: 22, color: C.sub)),
      );
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
        StreamBuilder<List<Post>>(
          stream: _postsFor(app, room, t),
          builder: (context, snap) {
            final posts = snap.data ?? const <Post>[];
            return FutureBuilder<Map<String, String>>(
              future: app.namesFor(room),
              builder: (context, ns) => _Meals(room: room, posts: posts, names: ns.data ?? const {}, t: t),
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

// ───────────────────────── 끼니 구역들 ─────────────────────────

class _Meals extends StatelessWidget {
  const _Meals({required this.room, required this.posts, required this.names, required this.t});
  final Room room;
  final List<Post> posts;
  final Map<String, String> names;
  final DateTime t;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.uid;
    final order = room.membersFor(me);
    Post? find(Meal m, String u) {
      for (final p in posts) {
        if (p.meal == m && p.uid == u) return p;
      }
      return null;
    }

    String nameOf(String u) => u == me ? '나' : (names[u] ?? '…');

    final out = <Widget>[];
    var noteShown = false;
    for (final meal in Meal.values) {
      final phase = meal.phase(t);
      final slots = [for (final u in order) _Slot(uid: u, name: nameOf(u), post: find(meal, u), mine: u == me)];
      switch (phase) {
        case MealPhase.now:
          out.add(_BigHeader(meal));
          out.add(_BigCard(meal: meal, room: room, slots: slots, t: t));
          out.add(const _LockNote());
          noteShown = true;
        case MealPhase.past:
          out.add(_SmallHeader(meal));
          out.add(_CompactCard(meal: meal, room: room, slots: slots, t: t));
        case MealPhase.upcoming:
          out.add(_LockedRow(meal));
      }
    }
    if (!noteShown) out.add(const _LockNote());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: out);
  }
}

class _Slot {
  _Slot({required this.uid, required this.name, required this.post, required this.mine});
  final String uid;
  final String name;
  final Post? post;
  final bool mine;
}

class _SmallHeader extends StatelessWidget {
  const _SmallHeader(this.meal);
  final Meal meal;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: SizedBox(
          height: 22,
          child: Row(children: [
            MealBadge(meal, size: 24),
            const SizedBox(width: 6),
            Text(meal.label, style: ts(15, w: FontWeight.w600, lh: 20)),
            const Spacer(),
            Text(meal.window(), style: ts(12, lh: 16, color: C.sub)),
          ]),
        ),
      );
}

class _BigHeader extends StatelessWidget {
  const _BigHeader(this.meal);
  final Meal meal;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: SizedBox(
          height: 28,
          child: Row(children: [
            MealBadge(meal, size: 30),
            const SizedBox(width: 6),
            Text(meal.label, style: ts(20, w: FontWeight.w700, lh: 25)),
            const SizedBox(width: 8),
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.track, borderRadius: BorderRadius.circular(10)),
              child: Text('지금', style: ts(12, w: FontWeight.w700, lh: 20, color: C.ink6)),
            ),
            const Spacer(),
            Text(meal.window(), style: ts(12, lh: 16, color: C.sub)),
          ]),
        ),
      );
}

class _LockNote extends StatelessWidget {
  const _LockNote();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(children: [
          const MIcon(Ic.lock, size: 12),
          const SizedBox(width: 5),
          Text('앨범에는 저장되지 않아요', style: ts(12, lh: 16, color: C.sub)),
        ]),
      );
}

class _LockedRow extends StatelessWidget {
  const _LockedRow(this.meal);
  final Meal meal;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.72),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 0, spreadRadius: 0.5)],
        ),
        child: Row(children: [
          MealBadge(meal, size: 24),
          const SizedBox(width: 8),
          Text(meal.label, style: ts(15, w: FontWeight.w600, lh: 20, color: C.ink3)),
          const SizedBox(width: 8),
          const MIcon(Ic.lockLight, size: 14),
          const Spacer(),
          Text(meal.window(), style: ts(12, lh: 16, color: C.sub)),
        ]),
      );
}

// ───────────────────────── 지난 끼니: 작은 사진 한 줄 ─────────────────────────

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.meal, required this.room, required this.slots, required this.t});
  final Meal meal;
  final Room room;
  final List<_Slot> slots;
  final DateTime t;

  @override
  Widget build(BuildContext context) {
    final cols = <Widget>[];
    for (var i = 0; i < kMaxMembers; i++) {
      if (i >= slots.length) {
        cols.add(const Expanded(child: SizedBox.shrink()));
      } else {
        final s = slots[i];
        Widget tile;
        if (s.post != null) {
          tile = PhotoThumb(s.post!.image, onTap: () => openPhoto(context, room, s.post!, s.name, s.mine));
        } else if (s.mine) {
          tile = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => startPost(context, meal: meal),
            child: const EmptyTile(),
          );
        } else {
          tile = const EmptyTile();
        }
        cols.add(Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == kMaxMembers - 1 ? 0 : 4),
            child: Column(children: [
              SizedBox(height: 52, width: double.infinity, child: tile),
              const SizedBox(height: 4),
              Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: ts(12, lh: 16, color: C.sub)),
            ]),
          ),
        ));
      }
    }
    return CardBox(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
    );
  }
}

// ───────────────────────── 지금 끼니: 큰 사진 칸 ─────────────────────────

class _BigCard extends StatelessWidget {
  const _BigCard({required this.meal, required this.room, required this.slots, required this.t});
  final Meal meal;
  final Room room;
  final List<_Slot> slots;
  final DateTime t;

  Widget _cell(BuildContext context, _Slot s) {
    if (s.post == null) {
      if (s.mine) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => startPost(context, meal: meal),
          child: Semantics(
            button: true,
            label: '나 ${meal.label} 사진 올리기',
            child: Container(color: C.white, alignment: Alignment.center, child: const MIcon(Ic.camera, size: 40)),
          ),
        );
      }
      return Stack(fit: StackFit.expand, children: [
        const EmptyTile(radius: 0, dashWidth: 18),
        Positioned(left: 8, right: 8, bottom: 8, child: Align(alignment: Alignment.bottomLeft, child: _Chip(name: s.name))),
      ]);
    }
    final p = s.post!;
    return GestureDetector(
      onTap: () => openPhoto(context, room, p, s.name, s.mine),
      child: Stack(fit: StackFit.expand, children: [
        PhotoFill(p.image),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Align(alignment: Alignment.bottomLeft, child: _Chip(name: s.name, menu: p.text, time: p.timeLabel)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += 2) {
      final a = slots[i];
      final b = i + 1 < slots.length ? slots[i + 1] : null;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 2));
      rows.add(SizedBox(
        height: 104,
        child: Row(children: [
          Expanded(child: _cell(context, a)),
          if (b != null) ...[const SizedBox(width: 2), Expanded(child: _cell(context, b))],
        ]),
      ));
    }

    final total = slots.length;
    final done = slots.where((s) => s.post != null).length;
    final myDone = slots.any((s) => s.mine && s.post != null);
    String lead;
    String? tail;
    if (done == 0) {
      lead = '아직 아무도 안 올렸어요';
    } else if (done == total) {
      lead = '모두 올렸어요';
    } else {
      lead = '$done명이 올렸어요';
      final left = total - done;
      tail = (!myDone && left == 1) ? ' · 나만 남았어요' : ' · $left명 남았어요';
    }

    return CardBox(
      clip: true,
      child: Column(children: [
        Container(color: C.white, child: Column(children: rows)),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: lead),
                  if (tail != null) TextSpan(text: tail, style: ts(15, w: FontWeight.w600, lh: 20, color: C.sub)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(15, w: FontWeight.w600, lh: 20),
              ),
            ),
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < total; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slots[i].post != null ? C.teal : null,
                    border: Border.all(color: slots[i].post != null ? C.teal : C.grayAE, width: 1),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// 사진 위 이름표: 이름 메뉴 시각
class _Chip extends StatelessWidget {
  const _Chip({required this.name, this.menu = '', this.time = ''});
  final String name;
  final String menu;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: 12,
      blur: 14,
      height: 24,
      shadows: const [],
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(name, style: ts(12, w: FontWeight.w700, lh: 24, color: C.ink)),
        if (menu.isNotEmpty) ...[
          const SizedBox(width: 5),
          Flexible(child: Text(menu, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, lh: 24, color: C.ink))),
        ],
        if (time.isNotEmpty) ...[
          const SizedBox(width: 5),
          Text(time, style: ts(12, lh: 24, color: C.ink6)),
        ],
      ]),
    );
  }
}

// ───────────────────────── 방이 하나도 없을 때 ─────────────────────────

class EmptyRooms extends StatelessWidget {
  const EmptyRooms({super.key});

  @override
  Widget build(BuildContext context) {
    Widget circle(String asset, double left) => Positioned(
          left: left,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x241E2846), offset: Offset(0, 3), blurRadius: 8),
                BoxShadow(color: C.bg, spreadRadius: 3),
              ],
            ),
            child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: CardBox(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(children: [
          SizedBox(
            width: 60 + 46 * 2,
            height: 60,
            child: Stack(children: [
              circle('assets/illust/food_salad.jpg', 0),
              circle('assets/illust/food_bibim.jpg', 46),
              circle('assets/illust/food_katsu.jpg', 92),
            ]),
          ),
          const SizedBox(height: 16),
          Text('아직 방이 없어요', style: ts(20, w: FontWeight.w700, lh: 25)),
          const SizedBox(height: 4),
          Text('방을 만들고 함께 먹는 사람을 초대해 보세요', textAlign: TextAlign.center, style: ts(15, lh: 20, color: C.sub)),
          const SizedBox(height: 20),
          SoftPill(icon: Ic.plusGray, label: '새 방 만들기', onTap: () => openRoomCreate(context)),
          const SizedBox(height: 10),
          SoftPill(icon: Ic.clipboard, label: '코드로 참여하기', onTap: () => openJoinRoom(context)),
        ]),
      ),
    );
  }
}
