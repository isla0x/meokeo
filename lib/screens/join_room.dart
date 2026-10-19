import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'invite.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _clean(String t) {
    final u = t.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return u.length > kCodeLength ? u.substring(0, kCodeLength) : u;
  }

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = _clean(d?.text ?? '');
    if (t.isNotEmpty) {
      _code.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    }
  }

  Future<void> _join() async {
    if (_busy || _code.text.length < kCodeLength) return;
    setState(() => _busy = true);
    try {
      final room = await Repo.instance.joinByCode(_code.text);
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => InviteScreen(roomId: room.id)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('참여하지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final code = _code.text;
    final ready = code.length == kCodeLength;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              const Text('코드로 참여하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: Stack(alignment: Alignment.center, children: [
                for (final e in const [['🥗', -52.0], ['🍲', 0.0], ['🍱', 52.0]])
                  Transform.translate(
                    offset: Offset(e[1] as double, 0),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle, boxShadow: softShadow()),
                      child: Text(e[0] as String, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('초대 코드를 입력해요', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('친구가 보내 준 8자리 코드예요', style: TextStyle(color: kMuted)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => _focus.requestFocus(),
              child: CodeBoxes(
                code: code,
                activeIndex: code.length < kCodeLength ? code.length : null,
                size: 34,
              ),
            ),
            // 실제 입력은 보이지 않는 입력창이 받아요
            SizedBox(
              height: 1,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _code,
                  focusNode: _focus,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    TextInputFormatter.withFunction((o, n) {
                      final t = _clean(n.text);
                      return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
                    }),
                  ],
                  onSubmitted: (_) => _join(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _paste,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow()),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.content_paste_rounded, size: 16, color: kTeal),
                  SizedBox(width: 6),
                  Text('복사한 코드 붙여넣기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const Spacer(),
            BigButton(
              label: _busy ? '참여하는 중…' : '참여하기',
              onPressed: (ready && !_busy) ? _join : null,
            ),
          ]),
        ),
      ),
    );
  }
}
