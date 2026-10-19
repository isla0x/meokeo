import 'package:flutter/cupertino.dart';

import '../data.dart';
import '../ui.dart';
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
          CupertinoPageRoute(builder: (_) => InviteScreen(roomId: room.id, justCreated: true)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('방을 만들지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _busy = false);
    showMessage(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryOf(context);
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        automaticallyImplyLeading: false,
        leading: NavTextButton('취소', () => Navigator.of(context).pop()),
        middle: const Text('새 방 만들기'),
      ),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          Section(
            headerText: '이름',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: CupertinoTextField(
                  controller: _name,
                  maxLength: 12,
                  placeholder: '예: 회사 동기',
                  decoration: null,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          Section(
            headerText: '방 아이콘',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (final k in kRoomKinds)
                    GestureDetector(
                      onTap: () => setState(() => _icon = k.key),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _icon == k.key ? kAccent : const Color(0x00000000), width: 2),
                        ),
                        child: RoomIconBox(kind: k.key, size: 54),
                      ),
                    ),
                ]),
              ),
            ],
          ),
          Section(
            headerText: '인원',
            footer: '방은 한 사람당 최대 3개까지 만들 수 있어요.',
            children: [
              Row1(
                title: '한 방에 함께할 수 있는 사람',
                trailing: Text('최대 4명', style: TextStyle(fontSize: 15, color: secondary)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: PrimaryButton(
              label: _busy ? '만드는 중…' : '방 만들기',
              onPressed: (_busy || _name.text.trim().isEmpty) ? null : _create,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('이미 초대 코드가 있나요?', style: TextStyle(fontSize: 13, color: secondary)),
              CupertinoButton(
                padding: const EdgeInsets.only(left: 6),
                minSize: 36,
                onPressed: () => Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(builder: (_) => const JoinRoomScreen(), fullscreenDialog: true)),
                child: const Text('코드로 참여하기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
