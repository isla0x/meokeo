import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../icons.dart';
import '../models.dart';
import '../repo/firebase_repo.dart' show errorDetail;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

Route<void> inviteRoute(Room room, {bool created = false}) =>
    CupertinoPageRoute<void>(builder: (_) => InvitePage(initial: room, created: created));

Future<void> openInvite(BuildContext context, Room room, {bool created = false}) =>
    Navigator.of(context, rootNavigator: true).push(inviteRoute(room, created: created));

const _banner = [
  'assets/illust/food_salad.jpg',
  'assets/illust/food_katsu.jpg',
  'assets/illust/food_bibim.jpg',
  'assets/illust/food_kimchi.jpg',
];

/// 방 사진 모음 (위쪽 띠)
class Collage extends StatelessWidget {
  const Collage({super.key, required this.height, this.children = const []});
  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(fit: StackFit.expand, children: [
        Row(children: [
          for (final a in _banner) Expanded(child: Image.asset(a, fit: BoxFit.cover, height: height)),
        ]),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0xA8000000)],
              stops: [0.15, 1.0],
            ),
          ),
        ),
        ...children,
      ]),
    );
  }
}

class InvitePage extends StatelessWidget {
  const InvitePage({super.key, required this.initial, this.created = false});
  final Room initial;
  final bool created;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    var room = initial;
    for (final r in app.rooms) {
      if (r.id == initial.id) room = r;
    }
    final isOwner = room.ownerId == app.uid;
    final total = room.members.length;

    return CupertinoPageScaffold(
      backgroundColor: C.bg,
      resizeToAvoidBottomInset: false,
      child: Stack(children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(height: topPad(context) + 44),
              HeaderTitle(sub: created ? '방을 만들었어요' : '함께 먹는 사람들', title: '친구 초대하기'),
              const SizedBox(height: 14),
              CardBox(
                clip: true,
                child: Column(children: [
                  Collage(height: 96, children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      child: Row(children: [
                        RoomBadge(room.icon, size: 26, glyph: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(18, w: FontWeight.w700, lh: 22, color: C.white).copyWith(
                              shadows: const [Shadow(color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 3)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Glass(
                          radius: 12,
                          blur: 14,
                          height: 24,
                          shadows: const [],
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('멤버 $total / $kMaxMembers', style: ts(12, w: FontWeight.w700, lh: 24, color: C.ink)),
                        ),
                      ]),
                    ),
                  ]),
                  _MemberRow(room: room),
                ]),
              ),
              const SizedBox(height: 12),
              CardBox(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text('초대 코드', style: ts(12, lh: 16, color: C.sub)),
                  const SizedBox(height: 10),
                  Semantics(
                    label: '초대 코드 ${room.codeSpaced}',
                    child: CodeRow(chars: room.code.split('')),
                  ),
                  const SizedBox(height: 12),
                  Text('코드를 입력하면 바로 들어올 수 있어요', style: ts(12, lh: 16, color: C.sub)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: SoftPill(
                        icon: Ic.copy,
                        label: '코드 복사',
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: room.code));
                          if (context.mounted) showToast(context, '초대 코드를 복사했어요');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SoftPill(
                        icon: Ic.share,
                        label: '공유하기',
                        onTap: () => Share.share(
                          '뭐먹어?에서 같이 먹어요!\n초대 코드: ${room.codeSpaced}\n앱에서 "코드로 참여하기"에 입력해 주세요.',
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
              FooterNote('$kMaxMembers명이 모이면 더 이상 들어올 수 없어요.', top: 10),
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 2, 26, 0),
                  child: Row(children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _regenerate(context, app, room),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text('코드 다시 만들기', style: ts(13, w: FontWeight.w600, lh: 18, color: C.teal)),
                      ),
                    ),
                    Flexible(child: Text('이전 코드는 쓸 수 없게 돼요', style: ts(12, lh: 16, color: C.sub))),
                  ]),
                ),
            ]),
          ),
        ),
        if (!created)
          Positioned(
            left: 0,
            right: 0,
            bottom: 104,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _leave(context, app, room),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('방 나가기', style: ts(13, w: FontWeight.w600, lh: 18, color: C.red)),
                ),
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 34,
          child: CtaButton(label: '완료', onTap: () => Navigator.of(context).pop()),
        ),
      ]),
    );
  }

  Future<void> _regenerate(BuildContext context, AppState app, Room room) async {
    final ok = await showConfirm(context,
        title: '코드를 다시 만들까요?', message: '이전 코드는 더 이상 쓸 수 없어요.', okLabel: '다시 만들기');
    if (!ok || !context.mounted) return;
    try {
      await app.repo.regenerateCode(room);
      if (context.mounted) showToast(context, '새 코드를 만들었어요');
    } catch (e) {
      if (context.mounted) await showAlert(context, e is AppException ? e.message : '다시 만들지 못했어요.\n(${errorDetail(e)})');
    }
  }

  Future<void> _leave(BuildContext context, AppState app, Room room) async {
    final ok = await showConfirm(context,
        title: '‘${room.name}’ 방에서 나갈까요?',
        message: '내가 올린 사진은 방에 그대로 남아요.',
        okLabel: '나가기',
        destructive: true);
    if (!ok || !context.mounted) return;
    try {
      await app.repo.leaveRoom(room);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) await showAlert(context, '나가지 못했어요.\n(${errorDetail(e)})');
    }
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return FutureBuilder<Map<String, String>>(
      future: app.namesFor(room),
      builder: (context, snap) {
        final names = snap.data ?? const <String, String>{};
        final order = room.membersFor(app.uid);
        const others = [C.indigo, C.amber, C.pink];
        final cols = <Widget>[];
        for (var i = 0; i < kMaxMembers; i++) {
          Widget avatar;
          String label;
          if (i < order.length) {
            final u = order[i];
            final mine = u == app.uid;
            label = mine ? '나' : (names[u] ?? '…');
            final initial = mine ? '나' : (label.isEmpty ? '?' : label.characters.first);
            avatar = Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mine ? C.teal : others[(i - 1) % others.length],
                shape: BoxShape.circle,
                boxShadow: mine ? const [BoxShadow(color: Color(0x4D2F7F7A), offset: Offset(0, 3), blurRadius: 8)] : null,
              ),
              child: Text(initial, style: ts(15, w: FontWeight.w700, lh: 20, color: C.white)),
            );
          } else {
            label = '빈 자리';
            avatar = const DashedRing(size: 52, child: MIcon(Ic.plus, size: 20));
          }
          cols.add(Expanded(
            child: Column(children: [
              avatar,
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, lh: 16, color: C.sub)),
            ]),
          ));
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
        );
      },
    );
  }
}
