import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';

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
          appBar: AppBar(
            title: Text(justCreated ? '방을 만들었어요' : (room?.name ?? '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('완료'),
              ),
            ],
          ),
          body: room == null
              ? const Center(child: CircularProgressIndicator())
              : _Body(room: room),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    final isOwner = room.ownerId == Repo.instance.uid;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text(room.icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(room.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('멤버 ${room.members.length} / $kMaxMembers',
            style: const TextStyle(color: kMuted)),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, String>>(
          future: Repo.instance.nicknames(room.members),
          builder: (context, s) {
            final names = s.data ?? const <String, String>{};
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in room.members)
                  Chip(
                    label: Text(m == Repo.instance.uid ? '나' : (names[m] ?? '…')),
                    backgroundColor: kPinkSoft,
                    side: BorderSide.none,
                  ),
                for (var i = room.members.length; i < kMaxMembers; i++)
                  const Chip(label: Text('빈 자리'), side: BorderSide(color: Color(0xFFE0E0E4))),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const Text('초대 코드', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(room.code,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 8)),
        ),
        const SizedBox(height: 8),
        const Text('코드를 입력하면 바로 들어올 수 있어요',
            textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: room.code));
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('코드를 복사했어요')));
            }
          },
          child: const Text('코드 복사'),
        ),
        const SizedBox(height: 8),
        const Text('4명이 모이면 더 이상 들어올 수 없어요.',
            textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13)),
        if (isOwner) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              try {
                await Repo.instance.regenerateCode(room);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('코드를 바꾸지 못했어요')));
                }
              }
            },
            child: const Text('코드 다시 만들기 (이전 코드는 쓸 수 없게 돼요)'),
          ),
        ],
        const SizedBox(height: 12),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () async {
            await Repo.instance.leaveRoom(room);
            if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
          child: const Text('이 방에서 나가기'),
        ),
      ],
    );
  }
}
