import 'package:flutter/material.dart';

import '../data.dart';
import '../theme.dart';

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
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('뭐먹어?',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: kPink)),
              const SizedBox(height: 8),
              const Text('방 친구들에게 보일 별명을 정해 주세요.',
                  style: TextStyle(fontSize: 16, color: kMuted)),
              const SizedBox(height: 24),
              TextField(
                controller: _c,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(hintText: '별명 (최대 10자)'),
              ),
              const Spacer(flex: 2),
              FilledButton(onPressed: _busy ? null : _save, child: const Text('시작하기')),
            ],
          ),
        ),
      ),
    );
  }
}
