import 'dart:async';
import 'dart:typed_data';

import '../models.dart';
import 'repo.dart';

/// 서버 없이 메모리에서만 도는 가짜 저장소. 화면 이미지를 뽑는 테스트에서 써요.
class DemoRepo extends Repo {
  DemoRepo({
    this.myUid = 'me',
    Map<String, String>? names,
    List<Room>? rooms,
    List<Post>? posts,
    this.nickname = '지민',
  })  : _names = names ?? {},
        _rooms = rooms ?? [],
        _posts = posts ?? [];

  final String myUid;
  String? nickname;
  final Map<String, String> _names;
  final List<Room> _rooms;
  final List<Post> _posts;
  final _roomsCtl = StreamController<List<Room>>.broadcast();
  final _postsCtl = StreamController<void>.broadcast();

  @override
  String get uid => myUid;

  @override
  Future<void> ensureSignedIn() async {}

  @override
  Future<String?> myNickname() async => nickname;

  @override
  Future<void> setNickname(String n) async => nickname = n;

  @override
  Future<Map<String, String>> nicknames(Iterable<String> uids) async =>
      {for (final u in uids) u: u == myUid ? (nickname ?? '나') : (_names[u] ?? '이름 없음')};

  @override
  Stream<List<Room>> myRooms() async* {
    yield List.of(_rooms);
    yield* _roomsCtl.stream;
  }

  @override
  Future<Room> createRoom({required String name, required RoomIcon icon}) async {
    final r = Room(
      id: 'r${_rooms.length + 1}',
      name: name,
      icon: icon,
      ownerId: myUid,
      members: [myUid],
      code: 'K7M29QX4',
    );
    _rooms.add(r);
    _roomsCtl.add(List.of(_rooms));
    return r;
  }

  @override
  Future<Room> joinByCode(String rawCode) async => throw AppException('없는 코드예요. 다시 확인해 주세요.');

  @override
  Future<void> regenerateCode(Room room) async {}

  @override
  Future<void> leaveRoom(Room room) async {
    _rooms.removeWhere((r) => r.id == room.id);
    _roomsCtl.add(List.of(_rooms));
  }

  @override
  Stream<List<Post>> postsOn(String roomId, String date) async* {
    List<Post> cur() => _posts.where((p) => p.date == date).toList();
    yield cur();
    await for (final _ in _postsCtl.stream) {
      yield cur();
    }
  }

  @override
  Future<void> uploadPost({
    required String roomId,
    required Meal meal,
    required DateTime day,
    required Uint8List photo,
    String text = '',
  }) async {
    final date = dayKey(day);
    _posts.removeWhere((p) => p.uid == myUid && p.meal == meal && p.date == date);
    _posts.add(Post(id: '${date}_${meal.name}_$myUid', uid: myUid, meal: meal, date: date, photo: photo, text: text, at: now()));
    _postsCtl.add(null);
  }

  @override
  Future<void> deletePost(String roomId, Post post) async {
    _posts.removeWhere((p) => p.id == post.id);
    _postsCtl.add(null);
  }
}
