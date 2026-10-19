import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'invite.dart';
import 'join_room.dart';

class RoomCreateScreen extends StatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  State<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends State<RoomCreateScreen> {
  final _name = TextEditingController();
  String _icon = 'people';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy || _name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final room = await Repo.instance.createRoom(name: _name.text, icon: _icon);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => InviteScreen(roomId: room.id, justCreated: true)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('방을 만들지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(children: [
            Stack(alignment: Alignment.center, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const Text('새 방 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(children: [
                const FoodBanner(height: 112),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: softShadow()),
                      child: RoomIconBox(kind: _icon, size: 72, radius: 24),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      height: 54,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow()),
                      child: Row(children: [
                        const Text('이름', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _name,
                            maxLength: 12,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: '예: 회사 동기',
                              counterText: '',
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const _Label('방 아이콘'),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: softShadow()),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        for (final k in kRoomKinds)
                          GestureDetector(
                            onTap: () => setState(() => _icon = k.key),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: _icon == k.key ? kTeal : Colors.transparent, width: 2),
                              ),
                              child: RoomIconBox(kind: k.key, size: 60, radius: 18),
                            ),
                          ),
                      ]),
                    ),
                    const _Label('인원'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow()),
                      child: const Row(children: [
                        Expanded(child: Text('한 방에 함께할 수 있는 사람', style: TextStyle(fontSize: 15))),
                        Text('최대 4명', style: TextStyle(fontSize: 15, color: kMuted)),
                      ]),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Text('방은 한 사람당 최대 3개까지 만들 수 있어요.',
                          style: TextStyle(fontSize: 12, color: kMuted)),
                    ),
                  ]),
                ),
              ]),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('이미 초대 코드가 있나요? ', style: TextStyle(color: kMuted, fontSize: 13)),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
                child: const Text('코드로 참여하기',
                    style: TextStyle(color: kTeal, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ]),
            const SizedBox(height: 12),
            BigButton(
              label: _busy ? '만드는 중…' : '방 만들기',
              onPressed: (_busy || _name.text.trim().isEmpty) ? null : _create,
            ),
          ]),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 18, 0, 8),
        child: Text(text, style: const TextStyle(fontSize: 13, color: kMuted)),
      );
}
