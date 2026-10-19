import 'package:flutter/cupertino.dart';

import '../icons.dart';
import '../model.dart';
import 'calendar.dart';
import 'today.dart';
import '../ui.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _model = RoomsModel();

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.white,
        border: const Border(top: BorderSide(color: kLine, width: 0.5)),
        activeColor: kAccent,
        inactiveColor: kSubtle,
        iconSize: 26,
        height: 56,
        items: const [
          BottomNavigationBarItem(icon: GlyphIcon(Glyph.fork), label: '오늘'),
          BottomNavigationBarItem(icon: GlyphIcon(Glyph.calendar), label: '캘린더'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (_) => index == 0 ? TodayPage(model: _model) : CalendarPage(model: _model),
        );
      },
    );
  }
}
