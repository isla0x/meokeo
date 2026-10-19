import 'package:flutter/cupertino.dart';

import '../data.dart';
import '../ui.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _c.text.trim();
    if (n.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await Repo.instance.setNickname(n);
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, '저장하지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 56, 0, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('뭐먹어?', style: font(34, FontWeight.w700, letterSpacing: -0.6).copyWith(color: kAccent)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Text('같이 먹는 사람들과 끼니를 나눠요', style: TextStyle(fontSize: 14, color: secondaryOf(context))),
            ),
            Section(
              headerText: '별명',
              footer: '방 친구들에게 보일 이름이에요. (최대 10자)',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: CupertinoTextField(
                    controller: _c,
                    maxLength: 10,
                    autofocus: true,
                    placeholder: '예: 채은',
                    decoration: null,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: PrimaryButton(label: '시작하기', onPressed: (_busy || _c.text.trim().isEmpty) ? null : _save),
            ),
          ],
        ),
      ),
    );
  }
}
