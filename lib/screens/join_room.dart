import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import 'invite.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = (d?.text ?? '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (t.isNotEmpty) setState(() => _code.text = t.length > kCodeLength ? t.substring(0, kCodeLength) : t);
  }

  Future<void> _join() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final room = await Repo.instance.joinByCode(_code.text);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => InviteScreen(roomId: room.id)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('참여하지 못했어요. 다시 해 주세요.');
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
        title: const Text('코드로 참여하기'),
        leadingWidth: 72,
        leading: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('초대 코드를 입력해요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('친구가 보내 준 8자리 코드예요', style: TextStyle(color: kMuted)),
          const SizedBox(height: 20),
          TextField(
            controller: _code,
            autofocus: true,
            maxLength: kCodeLength,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              TextInputFormatter.withFunction(
                  (o, n) => n.copyWith(text: n.text.toUpperCase())),
            ],
            decoration: const InputDecoration(counterText: '', hintText: 'K7M29QX4'),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: const Text('복사한 코드 붙여넣기'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _join, child: const Text('참여하기')),
        ],
      ),
    );
  }
}
