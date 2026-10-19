import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../icons.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo/firebase_repo.dart' show errorDetail;
import '../repo/repo.dart' show kMaxPhotoBytes;
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

final ImagePicker _picker = ImagePicker();

/// 사진을 찍어요. 카메라를 못 쓰면(시뮬레이터 등) 앨범에서 골라요.
Future<Uint8List?> _capture(BuildContext context) async {
  Future<Uint8List?> from(ImageSource src) async {
    final x = await _picker.pickImage(source: src, maxWidth: 1000, maxHeight: 1000, imageQuality: 60);
    return x == null ? null : await x.readAsBytes();
  }

  try {
    return await from(ImageSource.camera);
  } on PlatformException {
    // 카메라를 쓸 수 없는 경우 → 앨범
  } catch (_) {}
  try {
    return await from(ImageSource.gallery);
  } catch (_) {
    if (context.mounted) {
      await showAlert(context, '사진을 가져오지 못했어요.\n설정에서 카메라·사진 접근을 확인해 주세요.');
    }
    return null;
  }
}

/// 카메라 버튼 / 내 칸을 눌렀을 때. [meal]이 없으면 지금 시간으로 끼니를 정해요.
Future<void> startPost(BuildContext context, {Meal? meal}) async {
  final app = AppScope.read(context);
  if (app.rooms.isEmpty) {
    await showAlert(context, '먼저 방을 만들거나 참여해 주세요.');
    return;
  }
  final t = now();
  final m = meal ?? Meal.forPost(t);
  if (m == null) {
    showToast(context, '${clockKoMin(Meal.breakfast.startMin)}부터 올릴 수 있어요');
    return;
  }
  final bytes = await _capture(context);
  if (bytes == null || !context.mounted) return;
  await showMSheet<void>(context, (_) => PostSheet(meal: m, auto: meal == null, photo: bytes, takenAt: t));
}

class PostSheet extends StatefulWidget {
  const PostSheet({super.key, required this.meal, required this.auto, required this.photo, required this.takenAt, this.initialText = ''});
  final Meal meal;
  final bool auto; // 지금 시간으로 끼니를 골랐는지
  final Uint8List photo;
  final DateTime takenAt;
  final String initialText;

  @override
  State<PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<PostSheet> {
  late Uint8List _photo = widget.photo;
  late ImageProvider _image = MemoryImage(_photo);
  late final TextEditingController _text = TextEditingController(text: widget.initialText);
  Set<String>? _picked; // 처음엔 모든 방
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _retake() async {
    final b = await _capture(context);
    if (b == null || !mounted) return;
    setState(() {
      _photo = b;
      _image = MemoryImage(b);
    });
  }

  Future<void> _upload(List<Room> rooms) async {
    final app = AppScope.read(context);
    final targets = rooms.where((r) => _picked!.contains(r.id)).toList();
    if (targets.isEmpty || _busy) return;
    if (_photo.length > kMaxPhotoBytes) {
      await showAlert(context, '사진이 너무 커요. 다시 찍어 주세요.');
      return;
    }
    setState(() => _busy = true);
    final day = widget.takenAt;
    final failed = <String>[];
    String? firstError;
    await Future.wait(targets.map((r) async {
      try {
        await app.repo.uploadPost(roomId: r.id, meal: widget.meal, day: day, photo: _photo, text: _text.text.trim());
      } catch (e) {
        failed.add(r.name);
        firstError ??= e is AppException ? e.message : errorDetail(e);
      }
    }));
    if (!mounted) return;
    if (failed.length < targets.length) {
      await Notifier.instance.markPosted(day, widget.meal);
    }
    if (failed.isEmpty) {
      final nav = Navigator.of(context, rootNavigator: true);
      nav.pop();
      if (nav.mounted) showToast(nav.context, '${widget.meal.label} 사진을 올렸어요');
      return;
    }
    setState(() {
      _busy = false;
      _picked!.removeWhere((id) => rooms.any((r) => r.id == id && !failed.contains(r.name)));
    });
    await showAlert(context, '${failed.join(', ')} 방에는 올리지 못했어요.\n($firstError)');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final rooms = app.rooms;
    _picked ??= rooms.map((r) => r.id).toSet();
    final picked = _picked!;
    final count = rooms.where((r) => picked.contains(r.id)).length;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final t = widget.takenAt;

    Widget chip({required Widget child, VoidCallback? onTap}) => Glass(
          radius: 16,
          height: 32,
          blur: 14,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          shadows: const [],
          onTap: onTap,
          child: child,
        );

    return SheetFrame(
      title: '올리기',
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 4, bottom: 150 + kb),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  height: 232,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), spreadRadius: 0.5)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(fit: StackFit.expand, children: [
                      PhotoFill(_image),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: chip(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const MIcon(Ic.clock, size: 14),
                            const SizedBox(width: 6),
                            Text('${widget.meal.label} · ${clockKo(t.hour, t.minute)}', style: ts(12, w: FontWeight.w600, lh: 16, color: C.ink)),
                          ]),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Semantics(
                          button: true,
                          label: '다시 찍기',
                          child: chip(
                            onTap: _retake,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const MIcon(Ic.redo, size: 14),
                              const SizedBox(width: 6),
                              Text('다시 찍기', style: ts(12, w: FontWeight.w600, lh: 16, color: C.ink)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                FooterNote(widget.auto ? '지금 시간 기준으로 ${widget.meal.label}에 넣었어요' : '${widget.meal.label}에 올려요'),
                const SizedBox(height: 12),
                CardBox(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text('메뉴', style: ts(15, w: FontWeight.w600, lh: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _text,
                          textAlign: TextAlign.right,
                          padding: EdgeInsets.zero,
                          decoration: null,
                          maxLines: 1,
                          style: ts(15, lh: 20),
                          placeholder: '한 줄로 적어 보세요 (선택)',
                          placeholderStyle: ts(15, lh: 20, color: C.gray8),
                          cursorColor: C.teal,
                          inputFormatters: [LengthLimitingTextInputFormatter(30)],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SectionLabel('어느 방에 올릴까요?', top: 16),
                CardBox(
                  clip: true,
                  child: Column(children: [
                    for (var i = 0; i < rooms.length; i++)
                      SizedBox(
                        height: 60,
                        child: Stack(children: [
                          Positioned.fill(
                            child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(children: [
                              RoomBadge(rooms[i].icon, size: 32, glyph: 18, radius: 8),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(rooms[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, lh: 20)),
                                  Text('${rooms[i].members.length}명', style: ts(12, lh: 16, color: C.sub)),
                                ]),
                              ),
                              const SizedBox(width: 12),
                              MSwitch(
                                label: '${rooms[i].name} 방에 올리기',
                                value: picked.contains(rooms[i].id),
                                onChanged: (v) => setState(() {
                                  if (v) {
                                    picked.add(rooms[i].id);
                                  } else {
                                    picked.remove(rooms[i].id);
                                  }
                                }),
                              ),
                            ]),
                          )),
                          if (i != rooms.length - 1) const Positioned(left: 58, right: 0, bottom: 0, child: HairLine()),
                        ]),
                      ),
                  ]),
                ),
                const FooterNote('선택한 방 사람들만 볼 수 있고, 앨범에는 저장되지 않아요.'),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: kb > 0 ? kb + 12 : 34,
          child: CtaButton(
            label: count == 0 ? '방을 골라 주세요' : '$count개 방에 올리기',
            enabled: count > 0 && !_busy,
            onTap: () => _upload(rooms),
          ),
        ),
      ]),
    );
  }
}
