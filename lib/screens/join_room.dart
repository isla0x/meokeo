import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../icons.dart';
import '../models.dart';
import '../repo/firebase_repo.dart' show errorDetail;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// 코드로 참여하기 시트
Future<void> openJoinRoom(BuildContext context) async {
  await showMSheet<void>(context, (_) => const JoinRoomSheet());
}

/// 영문·숫자만, 대문자로, 8자까지
class CodeFormatter extends TextInputFormatter {
  const CodeFormatter();

  static String clean(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').characters.take(kCodeLength).toString();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = clean(newValue.text);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class JoinRoomSheet extends StatefulWidget {
  const JoinRoomSheet({super.key, this.initialCode = '', this.autofocus = true});
  final String initialCode;
  final bool autofocus;

  @override
  State<JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<JoinRoomSheet> {
  late final TextEditingController _ctl = TextEditingController(text: widget.initialCode);
  final FocusNode _focus = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _code => _ctl.text;
  bool get _ready => _code.length == kCodeLength && !_busy;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final t = CodeFormatter.clean(data?.text ?? '');
    if (t.isEmpty) {
      if (mounted) showToast(context, '복사한 코드가 없어요');
      return;
    }
    _ctl.value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
    _focus.requestFocus();
  }

  Future<void> _join() async {
    if (!_ready) return;
    final app = AppScope.read(context);
    final nav = Navigator.of(context, rootNavigator: true);
    setState(() => _busy = true);
    try {
      final room = await app.repo.joinByCode(_code);
      app.select(room.id);
      if (!mounted) return;
      nav.pop();
      if (nav.mounted) showToast(nav.context, '‘${room.name}’ 방에 들어왔어요');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showAlert(context, e is AppException ? e.message : '참여하지 못했어요.\n(${errorDetail(e)})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final chars = <String?>[for (var i = 0; i < kCodeLength; i++) i < _code.length ? _code[i] : null];
    final active = _code.length < kCodeLength ? _code.length : -1;

    return SheetFrame(
      title: '코드로 참여하기',
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: Column(children: [
              const SizedBox(height: 16),
              const _Avatars(),
              const SizedBox(height: 14),
              Text('초대 코드를 입력해요', style: ts(20, w: FontWeight.w700, lh: 25)),
              const SizedBox(height: 4),
              Text('친구가 보내 준 $kCodeLength자리 코드예요', style: ts(15, lh: 20, color: C.sub)),
              const SizedBox(height: 20),
              Semantics(
                label: '초대 코드 입력',
                child: CodeRow(chars: chars, width: 34, height: 46, fontSize: 22, activeIndex: active),
              ),
              const SizedBox(height: 14),
              Glass(
                radius: 17,
                height: 34,
                blur: 24,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onTap: _paste,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const MIcon(Ic.clipboard, size: 16),
                  const SizedBox(width: 6),
                  Text('복사한 코드 붙여넣기', style: ts(13, w: FontWeight.w600, lh: 18, color: C.ink3)),
                ]),
              ),
              // 눈에 안 보이는 입력칸: 키보드를 띄우고 글자를 받아요
              SizedBox(
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: CupertinoTextField(
                    controller: _ctl,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.visiblePassword,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: false,
                    showCursor: false,
                    inputFormatters: const [CodeFormatter()],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _join(),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: kb > 0 ? kb + 12 : 34,
          child: CtaButton(label: '참여하기', enabled: _ready, onTap: _join),
        ),
      ]),
    );
  }
}

class _Avatars extends StatelessWidget {
  const _Avatars();

  static const _imgs = ['assets/illust/food_salad.jpg', 'assets/illust/food_bibim.jpg', 'assets/illust/food_katsu.jpg'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60.0 * 3 - 28,
      height: 60,
      child: Stack(children: [
        for (var i = 0; i < _imgs.length; i++)
          Positioned(
            left: i * 46.0,
            top: 0,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x241E2846), offset: Offset(0, 3), blurRadius: 8),
                  BoxShadow(color: C.bg, spreadRadius: 3),
                ],
              ),
              child: ClipOval(child: Image.asset(_imgs[i], fit: BoxFit.cover, width: 60, height: 60)),
            ),
          ),
      ]),
    );
  }
}
