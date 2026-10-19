import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../repo/firebase_repo.dart' show errorDetail;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 처음 켰을 때: 방 사람들에게 보일 이름 정하기
class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final TextEditingController _ctl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  bool get _ready => _ctl.text.trim().isNotEmpty && !_busy;

  Future<void> _go() async {
    if (!_ready) return;
    final app = AppScope.read(context);
    setState(() => _busy = true);
    try {
      await app.saveNickname(_ctl.text);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showAlert(context, '저장하지 못했어요.\n인터넷을 확인해 주세요.\n(${errorDetail(e)})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return CupertinoPageScaffold(
      backgroundColor: C.bg,
      resizeToAvoidBottomInset: false,
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 150 + kb),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(height: topPad(context) + 64),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(88 * 0.225),
                      boxShadow: const [BoxShadow(color: Color(0x1F1E3250), offset: Offset(0, 8), blurRadius: 20)],
                    ),
                    child: const AppMark(size: 88),
                  ),
                ),
                const SizedBox(height: 22),
                Center(child: Text('뭐먹어?', style: ts(28, w: FontWeight.w700, lh: 34, ls: 0.37))),
                const SizedBox(height: 4),
                Center(child: Text('함께 먹는 사람들과 하루 세 끼를 나눠요', style: ts(15, lh: 20, color: C.sub))),
                const SizedBox(height: 28),
                CardBox(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text('이름', style: ts(15, w: FontWeight.w600, lh: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _ctl,
                          autofocus: false,
                          textAlign: TextAlign.right,
                          padding: EdgeInsets.zero,
                          decoration: null,
                          maxLines: 1,
                          style: ts(15, lh: 20),
                          placeholder: '예: 지민',
                          placeholderStyle: ts(15, lh: 20, color: C.gray8),
                          cursorColor: C.teal,
                          inputFormatters: [LengthLimitingTextInputFormatter(8)],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _go(),
                        ),
                      ),
                    ]),
                  ),
                ),
                const FooterNote('방에 있는 사람들에게 보이는 이름이에요.'),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: kb > 0 ? kb + 12 : 34,
          child: CtaButton(label: '시작하기', enabled: _ready, onTap: _go),
        ),
      ]),
    );
  }
}
