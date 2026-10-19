import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import 'room_screen.dart';
import 'join_room.dart';
import 'room_create.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뭐먹어?', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: '새 방 만들기',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const RoomCreateScreen(), fullscreenDialog: true)),
          ),
        ],
      ),
      body: StreamBuilder<List<Room>>(
        stream: Repo.instance.myRooms(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('방을 불러오지 못했어요.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snap.data!;
          if (rooms.isEmpty) return const _Empty();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _RoomTile(room: rooms[i]),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('아직 참여한 방이 없어요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('방을 만들거나, 친구가 보낸 코드로 들어와요.',
                textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RoomCreateScreen(), fullscreenDialog: true)),
              child: const Text('새 방 만들기'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
              child: const Text('코드로 참여하기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => RoomScreen(roomId: room.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: kPinkSoft, borderRadius: BorderRadius.circular(14)),
                child: Text(room.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('멤버 ${room.members.length} / $kMaxMembers',
                        style: const TextStyle(color: kMuted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}
