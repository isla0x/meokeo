import 'package:flutter/material.dart';

import '../data.dart';
import '../posts.dart';
import '../theme.dart';
import '../widgets.dart';
import 'calendar.dart';
import 'invite.dart';
import 'join_room.dart';
import 'notif_settings.dart';
import 'post_sheet.dart';
import 'room_create.dart';
import 'today_view.dart';

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; // 0 오늘, 1 캘린더
  String? _roomId;

  void _openCreate() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const RoomCreateScreen(), fullscreenDialog: true));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<List<Room>>(
      stream: Repo.instance.myRooms(),
      builder: (context, snap) {
        final rooms = snap.data ?? const <Room>[];
        Room? room;
        if (rooms.isNotEmpty) {
          room = rooms.firstWhere((r) => r.id == _roomId, orElse: () => rooms.first);
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    RoundIconButton(
                      icon: Icons.group_rounded,
                      onTap: room == null
                          ? _openCreate
                          : () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => InviteScreen(roomId: room!.id))),
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.notifications_none_rounded,
                      dot: true,
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const NotifSettingsScreen())),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${now.month}월 ${now.day}일 ${_weekdays[now.weekday - 1]}요일',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kMuted)),
                    Text(_tab == 0 ? '오늘' : '캘린더',
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.15)),
                  ]),
                ),
                if (rooms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                    child: Segmented(
                      labels: [for (final r in rooms) r.name],
                      index: rooms.indexWhere((r) => r.id == room!.id),
                      onChanged: (i) => setState(() => _roomId = rooms[i].id),
                      onAdd: rooms.length < kMaxRoomsPerUser ? _openCreate : null,
                    ),
                  ),
                Expanded(
                  child: !snap.hasData && !snap.hasError
                      ? const Center(child: CircularProgressIndicator())
                      : snap.hasError
                          ? Center(child: Text('방을 불러오지 못했어요.\n(${errorDetail(snap.error!)})', textAlign: TextAlign.center))
                          : room == null
                              ? _Empty(onCreate: _openCreate)
                              : (_tab == 0 ? TodayView(room: room) : CalendarView(room: room)),
                ),
              ]),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14 + MediaQuery.of(context).padding.bottom * 0.4,
                child: Row(children: [
                  Expanded(
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: softShadow()),
                      child: Row(children: [
                        _NavItem(icon: Icons.ramen_dining_rounded, label: '오늘', active: _tab == 0, onTap: () => setState(() => _tab = 0)),
                        _NavItem(icon: Icons.calendar_month_rounded, label: '캘린더', active: _tab == 1, onTap: () => setState(() => _tab = 1)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: room == null
                        ? _openCreate
                        : () => showPostSheet(context, room: room!, meal: Meal.forCamera(now), day: now),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: softShadow()),
                      child: const Icon(Icons.photo_camera_rounded, color: kTeal, size: 28),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: active ? const Color(0xFFF2F2F7) : Colors.transparent, borderRadius: BorderRadius.circular(27)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 24, color: active ? kTeal : kMuted),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? kInk : kMuted)),
          ]),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 100),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FoodBanner(height: 96),
          const SizedBox(height: 20),
          const Text('아직 참여한 방이 없어요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('방을 만들거나, 친구가 보낸 코드로 들어와요.',
              textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          const SizedBox(height: 22),
          BigButton(label: '새 방 만들기', onPressed: onCreate),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
            child: const Text('코드로 참여하기', style: TextStyle(color: kTeal, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
