import 'package:flutter/cupertino.dart';

import '../data.dart';
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
        child: const Icon(CupertinoIcons.person_2_fill, size: 22),
      ),
      CupertinoButton(
        padding: const EdgeInsets.only(left: 8),
        minSize: 36,
        onPressed: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const NotifSettingsScreen())),
        child: const Icon(CupertinoIcons.bell, size: 22),
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
Widget mealHeader(BuildContext context, Meal meal, {bool current = false, bool locked = false}) {
  final secondary = secondaryOf(context);
  return Row(children: [
    Icon(meal.icon, size: 13, color: meal.color),
    const SizedBox(width: 5),
    Text(meal.label, style: font(12, FontWeight.w600).copyWith(color: secondary)),
    if (locked) ...[
      const SizedBox(width: 4),
      Icon(CupertinoIcons.lock_fill, size: 11, color: secondary),
    ],
    if (current) ...[
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: CupertinoDynamicColor.resolve(kAccentSoft, context), borderRadius: BorderRadius.circular(8)),
        child: Text('지금',
            style: font(10, FontWeight.w600).copyWith(color: CupertinoDynamicColor.resolve(kAccentDeep, context))),
      ),
    ],
    const Spacer(),
    Text(meal.window, style: font(12, FontWeight.w400).copyWith(color: secondary)),
  ]);
}

// ───────── 사진 한 줄 ─────────
class PostRow extends StatelessWidget {
  const PostRow({super.key, required this.room, required this.member, required this.post, required this.onPost});
  final Room room;
  final Member member;
  final Post? post;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final p = post;
    final secondary = secondaryOf(context);
    final grey = CupertinoColors.systemGrey5.resolveFrom(context);

    Widget thumb;
    if (p != null) {
      thumb = Image.memory(p.photo, width: 52, height: 52, fit: BoxFit.cover, gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: grey));
    } else {
      thumb = Container(
        width: 52,
        height: 52,
        color: grey,
        alignment: Alignment.center,
        child: member.isMe
            ? const Icon(CupertinoIcons.camera_fill, size: 22, color: kAccent)
            : Text('—', style: TextStyle(color: secondary, fontSize: 18)),
      );
    }

    String sub;
    if (p != null) {
      sub = p.text.isEmpty ? hm(p.at) : '${p.text} · ${hm(p.at)}';
    } else {
      sub = member.isMe ? '탭해서 사진 올리기' : '아직이에요';
    }

    return Row1(
      minHeight: 68,
      leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: thumb),
      title: member.name,
      subtitle: sub,
      trailing: p != null ? Icon(CupertinoIcons.chevron_right, size: 14, color: secondary) : null,
      onTap: () {
        if (p != null) {
          Navigator.of(context).push(CupertinoPageRoute(builder: (_) => PhotoViewer(post: p, name: member.name)));
        } else if (member.isMe) {
          onPost();
        }
      },
      onLongPress: (member.isMe && p != null) ? () => _menu(context, p) : null,
    );
  }

  void _menu(BuildContext context, Post p) {
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
