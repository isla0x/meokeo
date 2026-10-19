import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'notifications.dart';
import 'repo/repo.dart';

/// 앱 전체가 같이 쓰는 상태: 로그인, 별명, 내가 들어 있는 방, 알림 설정
class AppState extends ChangeNotifier {
  AppState(this.repo, {this.useNotifications = true});

  final Repo repo;

  /// 화면 확인용 테스트에서는 끌 수 있어요
  final bool useNotifications;

  bool booted = false;
  Object? bootError;
  String? nickname;

  List<Room> rooms = const [];
  bool roomsLoaded = false;
  Object? roomsError;
  String? _selectedId;

  NotifSettings notif = NotifSettings.defaults();

  StreamSubscription<List<Room>>? _roomSub;
  final Map<String, Future<Map<String, String>>> _nameFutures = {};

  String get uid => repo.uid;

  bool get hasNickname => (nickname ?? '').trim().isNotEmpty;

  Room? get current {
    if (rooms.isEmpty) return null;
    return rooms.firstWhere((r) => r.id == _selectedId, orElse: () => rooms.first);
  }

  int get currentIndex {
    final c = current;
    return c == null ? 0 : rooms.indexOf(c);
  }

  Future<void> boot() async {
    bootError = null;
    booted = false;
    notifyListeners();
    try {
      await repo.ensureSignedIn();
      nickname = await repo.myNickname();
      booted = true;
      if (hasNickname) _startRooms();
    } catch (e) {
      bootError = e;
    }
    notifyListeners();
  }

  Future<void> saveNickname(String n) async {
    await repo.setNickname(n);
    nickname = n.trim();
    _startRooms();
    notifyListeners();
  }

  void _startRooms() {
    _roomSub?.cancel();
    roomsLoaded = false;
    _roomSub = repo.myRooms().listen((r) {
      rooms = r;
      roomsLoaded = true;
      roomsError = null;
      _watchPeers();
      notifyListeners();
    }, onError: (Object e) {
      roomsError = e;
      roomsLoaded = true;
      notifyListeners();
    });
    if (useNotifications) unawaited(_loadNotif());
  }

  Future<void> _loadNotif() async {
    try {
      notif = await Notifier.instance.load();
      final sp = await SharedPreferences.getInstance();
      if (!(sp.getBool('asked_notif') ?? false)) {
        await sp.setBool('asked_notif', true);
        await Notifier.instance.requestPermission();
      }
      await Notifier.instance.reschedule(notif);
      _watchPeers();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> saveNotif(NotifSettings s) async {
    notif = s;
    notifyListeners();
    if (useNotifications) await Notifier.instance.save(s);
    _watchPeers();
  }

  void select(String id) {
    _selectedId = id;
    notifyListeners();
  }

  void selectIndex(int i) {
    if (i >= 0 && i < rooms.length) select(rooms[i].id);
  }

  /// 방 구성원 이름표. 같은 구성원이면 한 번만 불러와요.
  Future<Map<String, String>> namesFor(Room room) {
    final key = '${room.id}:${room.members.join(',')}';
    return _nameFutures.putIfAbsent(key, () => repo.nicknames(room.members));
  }

  // ───────── 방 사람이 올렸을 때 (앱을 쓰는 중에만) ─────────
  final Map<String, StreamSubscription<List<Post>>> _peerSubs = {};
  final Set<String> _peerSeen = {};

  void _watchPeers() {
    for (final s in _peerSubs.values) {
      s.cancel();
    }
    _peerSubs.clear();
    if (!notif.peer) return;
    final today = dayKey(now());
    for (final r in rooms) {
      var first = true;
      _peerSubs[r.id] = repo.postsOn(r.id, today).listen((posts) async {
        for (final p in posts) {
          final key = '${r.id}/${p.id}';
          final fresh = _peerSeen.add(key);
          if (first || !fresh || p.uid == uid) continue;
          final names = await repo.nicknames([p.uid]);
          await Notifier.instance.showNow('${r.name} · ${names[p.uid] ?? '친구'}', '${p.meal.label} 사진을 올렸어요');
        }
        first = false;
      }, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    for (final s in _peerSubs.values) {
      s.cancel();
    }
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// 바뀌면 다시 그려요
  static AppState of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<AppScope>();
    return w!.notifier!;
  }

  /// 바뀌어도 다시 그리지 않아요 (버튼을 눌렀을 때 읽기용)
  static AppState read(BuildContext context) {
    final w = context.getInheritedWidgetOfExactType<AppScope>();
    return w!.notifier!;
  }
}
