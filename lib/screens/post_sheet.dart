import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../data.dart';
import '../posts.dart';
import '../ui.dart';

Future<void> showPostSheet(BuildContext context, {required Room room, required Meal meal, required DateTime day}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) => _PostSheet(room: room, meal: meal, day: day),
  );
}

class _PostSheet extends StatefulWidget {
  const _PostSheet({required this.room, required this.meal, required this.day});
  final Room room;
  final Meal meal;
  final DateTime day;

  @override
  State<_PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends State<_PostSheet> {
  final _picker = ImagePicker();
  final _text = TextEditingController();
  File? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      // 다시 인코딩되어 위치 등 메타데이터가 빠져요.
      final x = await _picker.pickImage(source: src, maxWidth: 1000, maxHeight: 1000, imageQuality: 60);
      if (x != null) setState(() => _photo = File(x.path));
    } catch (_) {
      if (mounted) showMessage(context, '사진을 가져오지 못했어요. 설정에서 카메라·사진 권한을 확인해 주세요.');
    }
  }

  Future<void> _submit() async {
    if (_photo == null || _busy) return;
    setState(() => _busy = true);
    try {
      await PostRepo.instance.upload(
          roomId: widget.room.id, meal: widget.meal, day: widget.day, photo: _photo!, text: _text.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        final big = e.toString().contains('too-large');
        showMessage(context, big ? '사진이 너무 커요. 다른 사진으로 해 주세요.' : '올리지 못했어요. 다시 해 주세요.\n(${errorDetail(e)})');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final secondary = secondaryOf(context);
    final grey = CupertinoColors.systemGrey5.resolveFrom(context);
    return DefaultTextStyle(
      style: CupertinoTheme.of(context).textTheme.textStyle,
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(kCardRadius))),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                NavTextButton('취소', () => Navigator.of(context).pop()),
                Expanded(
                  child: Column(children: [
                    Text('${widget.meal.label} 올리기', style: font(16, FontWeight.w600)),
                    Text('${widget.room.name} 방에만 보여요', style: TextStyle(fontSize: 11, color: secondary)),
                  ]),
                ),
                const SizedBox(width: 44),
              ]),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _photo == null
                      ? Container(color: grey, alignment: Alignment.center, child: const Icon(CupertinoIcons.camera_fill, size: 40, color: kAccent))
                      : Image.file(_photo!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoDynamicColor.resolve(kAccentSoft, context),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    onPressed: () => _pick(ImageSource.camera),
                    child: Text('촬영', style: font(15, FontWeight.w600).copyWith(color: CupertinoDynamicColor.resolve(kAccentDeep, context))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    color: CupertinoDynamicColor.resolve(kAccentSoft, context),
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    onPressed: () => _pick(ImageSource.gallery),
                    child: Text('앨범에서', style: font(15, FontWeight.w600).copyWith(color: CupertinoDynamicColor.resolve(kAccentDeep, context))),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: _text,
                maxLength: 30,
                placeholder: '메뉴 한 줄 (선택)',
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: _busy ? '올리는 중…' : '올리기', onPressed: (_photo == null || _busy) ? null : _submit),
            ]),
          ),
        ),
      ),
    );
  }
}
