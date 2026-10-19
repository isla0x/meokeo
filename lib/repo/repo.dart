import 'dart:typed_data';

import '../models.dart';

/// 화면이 서버와 이야기하는 통로. 실제로는 [FirebaseRepo], 화면 확인용은 [DemoRepo]가 채워요.
abstract class Repo {
  static late Repo instance;

  String get uid;

  Future<void> ensureSignedIn();

  // 별명
  Future<String?> myNickname();
  Future<void> setNickname(String nickname);
  Future<Map<String, String>> nicknames(Iterable<String> uids);

  // 방
  Stream<List<Room>> myRooms();
  Future<Room> createRoom({required String name, required RoomIcon icon});
  Future<Room> joinByCode(String rawCode);
  Future<void> regenerateCode(Room room);
  Future<void> leaveRoom(Room room);

  // 사진 글
  Stream<List<Post>> postsOn(String roomId, String date);
  Future<void> uploadPost({
    required String roomId,
    required Meal meal,
    required DateTime day,
    required Uint8List photo,
    String text = '',
  });
  Future<void> deletePost(String roomId, Post post);

  /// 내 사진·이름·방 참여를 모두 지우고 계정도 없애요.
  Future<void> deleteMyData();
}

/// 사진 한 장의 최대 크기 (보안 규칙의 800KB보다 조금 작게)
const int kMaxPhotoBytes = 760 * 1024;
