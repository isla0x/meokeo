import 'package:flutter/cupertino.dart';

import '../data.dart';
import '../icons.dart';
import '../model.dart';
import '../posts.dart';
import '../ui.dart';
import 'invite.dart';
import 'notif_settings.dart';
import 'room_create.dart';

class Member {
  Member(this.uid, this.name, this.index, this.isMe);
  final String uid;
  final String name;
  final int index;
  final bool isMe;
}

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// 방 멤버를 "나 먼저" 순서로 만들어요.
List<Member> buildMembers(Room room, Map<String, String> names) {
  final me = Repo.instance.uid;
  final order = [me, ...room.members.where((m) => m != me)];
  return [
    for (var i = 0; i < order.length; i++)
      Member(order[i], order[i] == me ? '나' : (names[order[i]] ?? '…'), i, order[i] == me),
  ];
}

// ───────── 위쪽 오른쪽 버튼 (멤버·알림) ─────────
class NavActions extends StatelessWidget {
  const NavActions({super.key, required this.model});
  final RoomsModel model;

  @override
  Widget build(BuildContext context) {
    final room = model.current;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minSize: 36,
        onPressed: () {
          final nav = Navigator.of(context);
          if (room == null) {
            nav.push(CupertinoPageRoute(builder: (_) => const RoomCreateScreen(), fullscreenDialog: true));
          } else {
            nav.push(CupertinoPageRoute(builder: (_) => InviteScreen(roomId: room.id)));
          }
        },
        child: const GlyphIcon(Glyph.people, size: 24),
      ),
      CupertinoButton(
        padding: const EdgeInsets.only(left: 8),
        minSize: 36,
        onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const NotifSettingsScreen())),
        child: const GlyphIcon(Glyph.bell, size: 24),
      ),
    ]);
  }
}

// ───────── 방 전환 ─────────
class RoomSwitcher extends StatelessWidget {
  const RoomSwitcher({super.key, required this.model});
  final RoomsModel model;

  @override
  Widget build(BuildContext context) {
    final rooms = model.rooms;
    final cur = model.current;
    if (cur == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 2),
      child: Row(children: [
        Expanded(
          child: rooms.length >= 2
              ? CupertinoSlidingSegmentedControl<String>(
                  groupValue: cur.id,
                  children: {
                    for (final r in rooms)
                      r.id: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: font(13, FontWeight.w600)),
                      ),
                  },
                  onValueChanged: (v) {
                    if (v != null) model.select(v);
                  },
                )
              : Row(children: [
                  RoomIconBox(kind: cur.icon, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(cur.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: font(17, FontWeight.w600, letterSpacing: -0.3)),
                  ),
                ]),
        ),
        if (rooms.length < kMaxRoomsPerUser)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minSize: 36,
            onPressed: () => Navigator.of(context)
                .push(CupertinoPageRoute(builder: (_) => const RoomCreateScreen(), fullscreenDialog: true)),
            child: const Icon(CupertinoIcons.plus_circle, size: 24),
          ),
      ]),
    );
  }
}

// ───────── 끼니 머리글 ─────────
Widget mealHeader(BuildContext context, Meal meal,
    {bool current = false, bool locked = false, int? posted, int? total}) {
  final done = posted != null && total != null && posted >= total && total > 0;
  return Row(children: [
    GlyphIcon(meal.glyph, size: 20, color: meal.color, stroke: 2.1),
    const SizedBox(width: 6),
    Text(meal.label, style: font(16, FontWeight.w700)),
    if (current) ...[
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: kAccentSoft.resolveFrom(context), borderRadius: BorderRadius.circular(6)),
        child: Text('지금', style: font(10, FontWeight.w600).copyWith(color: kIndigo)),
      ),
    ],
    const SizedBox(width: 8),
    Expanded(child: Text(meal.window, style: font(12, FontWeight.w400).copyWith(color: kSubtle))),
    if (locked)
      const Icon(CupertinoIcons.lock_fill, size: 13, color: kSubtle)
    else if (posted != null && total != null) ...[
      Container(width: 10, height: 10, decoration: BoxDecoration(color: done ? kMint : kLine, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: kAccentSoft.resolveFrom(context), borderRadius: BorderRadius.circular(6)),
        child: Text('$posted/$total', style: font(12, FontWeight.w600).copyWith(color: kIndigo)),
      ),
    ],
  ]);
}

// ───────── 사진 타일 (사람별 정사각 썸네일) ─────────
class TileEntry {
  TileEntry(this.member, this.post);
  final Member member;
  final Post? post;
}

class MealTiles extends StatelessWidget {
  const MealTiles({super.key, required this.room, required this.meal, required this.entries, required this.onPost});
  final Room room;
  final Meal meal;
  final List<TileEntry> entries;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(builder: (context, c) {
        const gap = 10.0;
        final size = ((c.maxWidth - gap * 3) / 4).floorToDouble().clamp(60.0, 92.0);
        return Wrap(spacing: gap, runSpacing: 14, children: [
          for (final e in entries) _Tile(room: room, entry: e, size: size, onPost: onPost),
        ]);
      }),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.room, required this.entry, required this.size, required this.onPost});
  final Room room;
  final TileEntry entry;
  final double size;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final p = entry.post;
    final m = entry.member;
    Widget thumb;
    if (p != null) {
      thumb = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(p.photo, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Container(width: size, height: size, color: kBand)),
      );
    } else if (m.isMe) {
      thumb = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCFD2E6), width: 1.5),
        ),
        child: const Center(child: GlyphIcon(Glyph.camera, size: 28, color: kIndigo)),
      );
    } else {
      thumb = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: kBand, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('—', style: font(18, FontWeight.w400).copyWith(color: kSubtle)),
      );
    }
    final sub = p != null ? (p.text.isEmpty ? hm(p.at) : p.text) : (m.isMe ? '올리기' : '아직이에요');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (p != null) {
          Navigator.of(context).push(CupertinoPageRoute(builder: (_) => PhotoViewer(post: p, name: m.name)));
        } else if (m.isMe) {
          onPost();
        }
      },
      onLongPress: (m.isMe && p != null) ? () => showPostMenu(context, room, p, onPost) : null,
      child: SizedBox(
        width: size,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          thumb,
          const SizedBox(height: 6),
          Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: font(12, FontWeight.w700)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: font(11, FontWeight.w400).copyWith(color: kSubtle)),
        ]),
      ),
    );
  }
}

void showPostMenu(BuildContext context, Room room, Post p, VoidCallback onPost) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(ctx);
            onPost();
          },
          child: const Text('다시 올리기'),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.pop(ctx);
            await PostRepo.instance.delete(room.id, p);
          },
          child: const Text('사진 지우기'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
    ),
  );
}

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.post, required this.name});
  final Post post;
  final String name;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: Text('$name · ${post.meal.label} ${hm(post.at)}', style: const TextStyle(color: CupertinoColors.white, fontSize: 15)),
      ),
      child: SafeArea(
        child: Column(children: [
          Expanded(child: InteractiveViewer(child: Center(child: Image.memory(post.photo)))),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(post.text, style: const TextStyle(color: CupertinoColors.white, fontSize: 16)),
            ),
        ]),
      ),
    );
  }
}
