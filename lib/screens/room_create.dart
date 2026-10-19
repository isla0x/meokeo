import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import 'invite.dart';
import 'join_room.dart';

const List<String> kRoomIcons = ['🍚', '🍜', '🍕', '🍣', '🥗', '🍔', '☕', '🍰'];

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final _name = TextEditingController();
  String _icon = kRoomIcons.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final room = await Repo.instance.createRoom(name: _name.text, icon: _icon);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => InviteScreen(roomId: room.id, justCreated: true)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('방을 만들지 못했어요. 다시 해 주세요.');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 방 만들기'),
        leadingWidth: 72,
        leading: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('이름', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            maxLength: 12,
            decoration: const InputDecoration(hintText: '예: 가족, 연인, 회사 동기'),
          ),
          const SizedBox(height: 12),
          const Text('방 아이콘', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final ic in kRoomIcons)
                GestureDetector(
                  onTap: () => setState(() => _icon = ic),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _icon == ic ? kPinkSoft : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _icon == ic ? kPink : Colors.transparent, width: 2),
                    ),
                    child: Text(ic, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('인원', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('한 방에 함께할 수 있는 사람: 최대 4명', style: TextStyle(color: kMuted)),
          const SizedBox(height: 6),
          const Text('방은 한 사람당 최대 3개까지 참여할 수 있어요.',
              style: TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Text('이미 초대 코드가 있나요?', style: TextStyle(color: kMuted))),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
                child: const Text('코드로 참여하기'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _create, child: const Text('방 만들기')),
        ],
      ),
    );
  }
}
