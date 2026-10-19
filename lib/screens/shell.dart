import 'package:flutter/cupertino.dart';

import '../theme.dart';
import '../widgets.dart';
import 'calendar.dart';
import 'post_flow.dart';
import 'today.dart';

/// 오늘 · 캘린더 두 화면과 아래 알약 탭바 + 카메라 버튼
class Shell extends StatefulWidget {
  const Shell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: C.bg,
      resizeToAvoidBottomInset: false,
      child: Stack(children: [
        Positioned.fill(
          child: IndexedStack(index: _tab, children: const [TodayPage(), CalendarPage()]),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: PillBar(
            index: _tab,
            onTab: (i) => setState(() => _tab = i),
            onCamera: () => startPost(context),
          ),
        ),
      ]),
    );
  }
}
