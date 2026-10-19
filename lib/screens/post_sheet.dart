import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data.dart';
import '../posts.dart';
import '../theme.dart';

Future<void> showPostSheet(BuildContext context,
    {required Room room, required Meal meal, required DateTime day}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _PostSheet(room: room, meal: meal, day: day),
    ),
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
      final x = await _picker.pickImage(
          source: src, maxWidth: 1000, maxHeight: 1000, imageQuality: 60);
      if (x != null) setState(() => _photo = File(x.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('사진을 가져오지 못했어요. 설정에서 권한을 확인해 주세요.')));
      }
    }
  }

  Future<void> _submit() async {
    if (_photo == null || _busy) return;
    setState(() => _busy = true);
    try {
      await PostRepo.instance.upload(
          roomId: widget.room.id,
          meal: widget.meal,
          day: widget.day,
          photo: _photo!,
          text: _text.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        final big = e.toString().contains('too-large');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(big ? '사진이 너무 커요. 다른 사진으로 해 주세요.' : '올리지 못했어요. 다시 해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.meal.emoji} ${widget.meal.label} 올리기',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${widget.room.icon} ${widget.room.name} 방에만 보여요',
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 14),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _photo == null
                    ? Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Text('📷', style: TextStyle(fontSize: 44)),
                      )
                    : Image.file(_photo!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('촬영'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('앨범에서'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              maxLength: 30,
              decoration: const InputDecoration(hintText: '한 줄 (선택)', counterText: ''),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_photo == null || _busy) ? null : _submit,
              child: Text(_busy ? '올리는 중…' : '올리기'),
            ),
          ],
        ),
      ),
    );
  }
}
