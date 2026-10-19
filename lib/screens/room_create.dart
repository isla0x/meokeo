import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../repo/firebase_repo.dart' show errorDetail;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'invite.dart';
import 'join_room.dart';

/// 새 방 만들기 시트. 만들면 바로 초대 화면으로 가요.
Future<void> openRoomCreate(BuildContext context) async {
  await showMSheet<void>(context, (_) => const RoomCreateSheet());
}

class RoomCreateSheet extends StatefulWidget {
  const RoomCreateSheet({super.key, this.initialName = '', this.initialIcon = RoomIcon.people});
  final String initialName;
  final RoomIcon initialIcon;

  @override
  State<RoomCreateSheet> createState() => _RoomCreateSheetState();
}

class _RoomCreateSheetState extends State<RoomCreateSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.initialName);
  late RoomIcon _icon = widget.initialIcon;
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

  bool get _ready => _name.text.trim().isNotEmpty && !_busy;

  Future<void> _create() async {
    if (!_ready) return;
    final app = AppScope.read(context);
    final nav = Navigator.of(context, rootNavigator: true);
    if (app.rooms.length >= kMaxRoomsPerUser) {
      await showAlert(context, '방은 한 사람당 최대 $kMaxRoomsPerUser개까지 만들 수 있어요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final room = await app.repo.createRoom(name: _name.text.trim(), icon: _icon);
      app.select(room.id);
      if (!mounted) return;
      nav.pop();
      await nav.push(inviteRoute(room, created: true));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showAlert(context, e is AppException ? e.message : '방을 만들지 못했어요.\n(${errorDetail(e)})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return SheetFrame(
      title: '새 방 만들기',
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 4, bottom: 190 + kb),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // 사진 띠 + 고른 아이콘
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 148,
                    child: Stack(children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: Semantics(
                          label: '함께 먹은 음식 사진 예시',
                          child: Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: kCardShadow),
                            child: ClipRRect(borderRadius: BorderRadius.circular(24), child: const Collage(height: 112)),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: Semantics(
                            label: '선택한 방 아이콘 미리보기',
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _icon.color,
                                borderRadius: BorderRadius.circular(21),
                                boxShadow: [
                                  BoxShadow(color: _icon.color.withAlpha(87), offset: const Offset(0, 6), blurRadius: 14),
                                  const BoxShadow(color: C.bg, spreadRadius: 4),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: RoomBadgeGlyph(_icon, glyph: 38),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                CardBox(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text('이름', style: ts(15, w: FontWeight.w600, lh: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _name,
                          textAlign: TextAlign.right,
                          padding: EdgeInsets.zero,
                          decoration: null,
                          maxLines: 1,
                          style: ts(15, lh: 20),
                          placeholder: '예: 가족, 회사 동기',
                          placeholderStyle: ts(15, lh: 20, color: C.gray8),
                          cursorColor: C.accent,
                          inputFormatters: [LengthLimitingTextInputFormatter(10)],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SectionLabel('방 아이콘', top: 18),
                CardBox(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final ic in RoomIcon.values) _IconChoice(icon: ic, selected: ic == _icon, onTap: () => setState(() => _icon = ic)),
                  ]),
                ),
                const SectionLabel('인원', top: 18),
                CardBox(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text('한 방에 함께할 수 있는 사람', style: ts(15, lh: 20)),
                      const Spacer(),
                      Text('최대 $kMaxMembers명', style: ts(15, lh: 20, color: C.sub)),
                    ]),
                  ),
                ),
                FooterNote('방은 한 사람당 최대 $kMaxRoomsPerUser개까지 만들 수 있어요.'),
              ]),
            ),
          ),
        ),
        if (kb == 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 104,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final nav = Navigator.of(context, rootNavigator: true);
                  nav.pop();
                  await Future<void>.delayed(const Duration(milliseconds: 60));
                  if (nav.mounted) await openJoinRoom(nav.context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text.rich(TextSpan(
                    style: ts(13, lh: 18, color: C.sub),
                    children: [
                      const TextSpan(text: '이미 초대 코드가 있나요? '),
                      TextSpan(text: '코드로 참여하기', style: ts(13, w: FontWeight.w600, lh: 18, color: C.accent)),
                    ],
                  )),
                ),
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: kb > 0 ? kb + 12 : 34,
          child: CtaButton(label: '방 만들기', enabled: _ready, onTap: _create),
        ),
      ]),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.icon, required this.selected, required this.onTap});
  final RoomIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${icon.label} 아이콘',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: icon.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? const [BoxShadow(color: C.accent, spreadRadius: 4), BoxShadow(color: C.white, spreadRadius: 2)]
                : null,
          ),
          alignment: Alignment.center,
          child: RoomBadgeGlyph(icon, glyph: icon == RoomIcon.dining ? 30 : (selected ? 32 : 30)),
        ),
      ),
    );
  }
}
