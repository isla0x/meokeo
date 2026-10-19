import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

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
        return Scaffold(
          body: SafeArea(
            child: room == null
                ? const Center(child: CircularProgressIndicator())
                : _Body(room: room, justCreated: justCreated),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.room, required this.justCreated});
  final Room room;
  final bool justCreated;

  @override
  Widget build(BuildContext context) {
    final me = Repo.instance.uid;
    final isOwner = room.ownerId == me;
    final code = room.code.length == kCodeLength
        ? '${room.code.substring(0, 4)}-${room.code.substring(4)}'
        : room.code;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(children: [
        Expanded(
          child: ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(justCreated ? '방을 만들었어요' : '${room.name} 멤버',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                const Text('친구 초대하기',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15)),
              ]),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(kRadius), boxShadow: softShadow()),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                SizedBox(
                  height: 100,
                  child: Stack(fit: StackFit.expand, children: [
                    Row(children: [
                      for (final c in const [Color(0xFFE9EFDD), Color(0xFFF6EBD3), Color(0xFF3B3F4A), Color(0xFFF2D9D4)])
                        Expanded(child: Container(color: c)),
                    ]),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x99000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      right: 12,
                      child: Row(children: [
                        RoomIconBox(kind: room.icon, size: 28, radius: 8),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(room.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
                          child: Text('멤버 ${room.members.length} / $kMaxMembers',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: FutureBuilder<Map<String, String>>(
                    future: Repo.instance.nicknames(room.members),
                    builder: (context, s) {
                      final names = s.data ?? const <String, String>{};
                      final order = [me, ...room.members.where((m) => m != me)];
                      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        for (var i = 0; i < kMaxMembers; i++)
                          Column(children: [
                            i < order.length
                                ? Avatar(name: names[order[i]] ?? '', index: i, isMe: order[i] == me)
                                : const EmptySeat(),
                            const SizedBox(height: 6),
                            Text(
                              i < order.length ? (order[i] == me ? '나' : (names[order[i]] ?? '…')) : '빈 자리',
                              style: const TextStyle(fontSize: 12, color: kMuted),
                            ),
                          ]),
                      ]);
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(kRadius), boxShadow: softShadow()),
              child: Column(children: [
                const Text('초대 코드', style: TextStyle(fontSize: 13, color: kMuted)),
                const SizedBox(height: 12),
                CodeBoxes(code: room.code, size: 32),
                const SizedBox(height: 10),
                const Text('코드를 입력하면 바로 들어올 수 있어요',
                    style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: PillButton(
                      icon: Icons.copy_rounded,
                      label: '코드 복사',
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: room.code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('코드를 복사했어요')));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      icon: Icons.ios_share_rounded,
                      label: '공유하기',
                      onTap: () => Share.share(
                          '뭐먹어? 앱에서 "${room.name}" 방에 초대해요. 초대 코드: $code'),
                    ),
                  ),
                ]),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 12, 10, 4),
              child: Text('4명이 모이면 더 이상 들어올 수 없어요.',
                  style: TextStyle(fontSize: 12, color: kMuted)),
            ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        await Repo.instance.regenerateCode(room);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('코드를 바꾸지 못했어요')));
                        }
                      }
                    },
                    child: const Text('코드 다시 만들기',
                        style: TextStyle(color: kTeal, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  const Text('이전 코드는 쓸 수 없게 돼요', style: TextStyle(fontSize: 12, color: kMuted)),
                ]),
              ),
            if (!justCreated)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 0),
                child: GestureDetector(
                  onTap: () async {
                    await Repo.instance.leaveRoom(room);
                    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text('이 방에서 나가기',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
          ]),
        ),
        BigButton(
          label: '완료',
          filled: false,
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ]),
    );
  }
}
