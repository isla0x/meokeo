import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../data.dart';
import '../ui.dart';
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
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
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
      Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (_) => InviteScreen(roomId: room.id)));
    } on AppException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('참여하지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() => _busy = false);
    showMessage(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _code.text.length == kCodeLength;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        automaticallyImplyLeading: false,
        leading: NavTextButton('취소', () => Navigator.of(context).pop()),
        middle: const Text('코드로 참여하기'),
      ),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          Section(
            headerText: '초대 코드',
            footer: '친구가 보내 준 8자리 코드예요.',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CupertinoTextField(
                  controller: _code,
                  autofocus: true,
                  maxLength: kCodeLength,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  placeholder: 'K7M29QX4',
                  decoration: null,
                  style: font(26, FontWeight.w700, letterSpacing: 5),
                  inputFormatters: [
                    TextInputFormatter.withFunction((o, n) {
                      final t = _clean(n.text);
                      return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
                    }),
                  ],
                  onSubmitted: (_) => _join(),
                ),
              ),
              Row1(
                leading: const Icon(CupertinoIcons.doc_on_clipboard, size: 18, color: kAccent),
                title: '복사한 코드 붙여넣기',
                titleColor: CupertinoDynamicColor.resolve(kAccentDeep, context),
                onTap: _paste,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            child: PrimaryButton(label: _busy ? '참여하는 중…' : '참여하기', onPressed: (ready && !_busy) ? _join : null),
          ),
        ]),
      ),
    );
  }
}
