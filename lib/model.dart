import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data.dart';

/// 내가 들어 있는 방 목록과 지금 보고 있는 방. 오늘·캘린더 탭이 함께 써요.
class RoomsModel extends ChangeNotifier {
  RoomsModel() {
    _sub = Repo.instance.myRooms().listen((r) {
      rooms = r;
      loaded = true;
      error = null;
      notifyListeners();
    }, onError: (Object e) {
      error = e;
      loaded = true;
      notifyListeners();
    });
  }

  late final StreamSubscription<List<Room>> _sub;
  List<Room> rooms = const [];
  bool loaded = false;
  Object? error;
  String? _selected;

  Room? get current {
    if (rooms.isEmpty) return null;
    return rooms.firstWhere((r) => r.id == _selected, orElse: () => rooms.first);
  }

  void select(String id) {
    _selected = id;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
