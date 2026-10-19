import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../ui.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key, required this.roomId, this.justCreated = false});
  final String roomId;
  final bool justCreated;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room?>(
      stream: Repo.instance.room(roomId),
      builder: (context, snap) {
        final room = snap.data;
        return CupertinoPageScaffold(
          backgroundColor: kBand,
          child: CustomScrollView(slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('친구 초대하기'),
              backgroundColor: kBand,
              trailing: justCreated
                  ? NavTextButton('완료', () => Navigator.of(context).popUntil((r) => r.isFirst), bold: true)
                  : null,
            ),
            SliverToBoxAdapter(
              child: room == null
                  ? const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CupertinoActivityIndicator()))
                  : _Body(room: room, justCreated: justCreated),
            ),
          ]),
        );
      },
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.room, required this.justCreated});
  final Room room;
  final bool justCreated;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final me = Repo.instance.uid;
    final isOwner = room.ownerId == me;
    final secondary = secondaryOf(context);
    final code = room.code.length == kCodeLength ? '${room.code.substring(0, 4)}-${room.code.substring(4)}' : room.code;
    final deep = CupertinoDynamicColor.resolve(kAccentDeep, context);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
        child: Row(children: [
          RoomIconBox(kind: room.icon, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text(room.name, style: font(17, FontWeight.w600, letterSpacing: -0.3))),
        ]),
      ),
      FutureBuilder<Map<String, String>>(
        future: Repo.instance.nicknames(room.members),
        builder: (context, s) {
          final names = s.data ?? const <String, String>{};
          final order = [me, ...room.members.where((m) => m != me)];
          return Section(
            headerText: '멤버 ${room.members.length} / $kMaxMembers',
            indent: 66,
            children: [
              for (var i = 0; i < order.length; i++)
                Row1(
                  leading: Avatar(name: names[order[i]] ?? '', index: i, isMe: order[i] == me),
                  title: order[i] == me ? '나' : (names[order[i]] ?? '…'),
                  trailing: order[i] == room.ownerId
                      ? Text('방장', style: TextStyle(fontSize: 12, color: secondary))
                      : null,
                ),
              for (var i = order.length; i < kMaxMembers; i++)
                Row1(
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, border: Border.all(color: CupertinoColors.systemGrey3.resolveFrom(context))),
                    child: Icon(CupertinoIcons.add, size: 16, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                  ),
                  title: '빈 자리',
                  titleColor: secondary,
                ),
            ],
          );
        },
      ),
      Section(
        headerText: '초대 코드',
        footer: '코드를 입력하면 바로 들어올 수 있어요. 4명이 모이면 더 이상 들어올 수 없어요.',
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text(code, style: font(30, FontWeight.w700, letterSpacing: 5))),
          ),
          Row1(
            leading: const Icon(CupertinoIcons.doc_on_doc, size: 18, color: kAccent),
            title: _copied ? '복사했어요' : '코드 복사',
            titleColor: deep,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: room.code));
              if (mounted) setState(() => _copied = true);
            },
          ),
          Row1(
            leading: const Icon(CupertinoIcons.share, size: 18, color: kAccent),
            title: '공유하기',
            titleColor: deep,
            onTap: () => Share.share('뭐먹어? 앱에서 "${room.name}" 방에 초대해요. 초대 코드: $code'),
          ),
        ],
      ),
      if (isOwner)
        Section(
          footer: '이전 코드는 쓸 수 없게 돼요.',
          children: [
            Row1(
              leading: const Icon(CupertinoIcons.refresh, size: 18, color: kAccent),
              title: '코드 다시 만들기',
              titleColor: deep,
              onTap: () async {
                try {
                  await Repo.instance.regenerateCode(room);
                  if (mounted) setState(() => _copied = false);
                } catch (_) {
                  if (mounted) showMessage(context, '코드를 바꾸지 못했어요.');
                }
              },
            ),
          ],
        ),
      if (!widget.justCreated)
        Section(children: [
          Row1(
            title: '이 방에서 나가기',
            titleColor: CupertinoColors.destructiveRed,
            onTap: () => _confirmLeave(context, room),
          ),
        ]),
      const SizedBox(height: 24),
    ]);
  }

  void _confirmLeave(BuildContext context, Room room) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('이 방에서 나갈까요?'),
        content: const Text('나간 뒤에도 코드로 다시 들어올 수 있어요.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await Repo.instance.leaveRoom(room);
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }
}
