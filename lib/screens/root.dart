import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

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
        backgroundColor: const CupertinoDynamicColor.withBrightness(
          color: Color(0xFFF9F9F9),
          darkColor: Color(0xFF1D1D1D),
        ),
        activeColor: kAccent,
        inactiveColor: CupertinoColors.secondaryLabel,
        iconSize: 26,
        height: 56,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: '오늘'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.calendar), label: '캘린더'),
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
