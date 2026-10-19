import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

const int kMaxMembers = 4;
const int kMaxRoomsPerUser = 3;
const int kCodeLength = 8;

/// 헷갈리는 글자(0/O, 1/I/L)를 뺀 초대 코드 글자들
const String _codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

class Room {
  Room({
    required this.id,
    required this.name,
    required this.icon,
    required this.ownerId,
    required this.members,
    required this.code,
  });

  final String id;
  final String name;
  final String icon;
  final String ownerId;
  final List<String> members;
  final String code;

  factory Room.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Room(
      id: d.id,
      name: (m['name'] as String?) ?? '',
      icon: (m['icon'] as String?) ?? '🍚',
      ownerId: (m['ownerId'] as String?) ?? '',
      members: List<String>.from((m['members'] as List?) ?? const []),
      code: (m['code'] as String?) ?? '',
    );
  }
}

class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 서버(Firebase)와 이야기하는 곳. 화면은 이 클래스만 써요.
class Repo {
  Repo._();
  static final Repo instance = Repo._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => _auth.currentUser!.uid;

  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ───────── 별명 ─────────
  Future<String?> myNickname() async {
    final d = await _db.collection('users').doc(uid).get();
    return d.data()?['nickname'] as String?;
  }

  Future<void> setNickname(String nickname) async {
    await _db.collection('users').doc(uid).set(
      {'nickname': nickname.trim(), 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<Map<String, String>> nicknames(Iterable<String> uids) async {
    final out = <String, String>{};
    for (final id in uids) {
      final d = await _db.collection('users').doc(id).get();
      out[id] = (d.data()?['nickname'] as String?) ?? '이름 없음';
    }
    return out;
  }

  // ───────── 방 ─────────
  Stream<List<Room>> myRooms() {
    return _db
        .collection('rooms')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((s) => s.docs.map(Room.fromDoc).toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Stream<Room?> room(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((d) => d.exists ? Room.fromDoc(d) : null);
  }

  Future<int> _myRoomCount() async {
    final s = await _db
        .collection('rooms')
        .where('members', arrayContains: uid)
        .count()
        .get();
    return s.count ?? 0;
  }

  String _randomCode() {
    final r = Random.secure();
    return List.generate(
        kCodeLength, (_) => _codeChars[r.nextInt(_codeChars.length)]).join();
  }

  Future<String> _freshCode() async {
    for (var i = 0; i < 8; i++) {
      final c = _randomCode();
      final d = await _db.collection('codes').doc(c).get();
      if (!d.exists) return c;
    }
    throw AppException('코드를 만들지 못했어요. 잠시 뒤 다시 해 주세요.');
  }

  Future<Room> createRoom({required String name, required String icon}) async {
    final n = name.trim();
    if (n.isEmpty) throw AppException('방 이름을 적어 주세요.');
    if (await _myRoomCount() >= kMaxRoomsPerUser) {
      throw AppException('방은 한 사람당 최대 $kMaxRoomsPerUser개까지 참여할 수 있어요.');
    }
    final code = await _freshCode();
    final ref = _db.collection('rooms').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'name': n,
      'icon': icon,
      'ownerId': uid,
      'members': [uid],
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('codes').doc(code), {'roomId': ref.id});
    await batch.commit();
    return Room.fromDoc(await ref.get());
  }

  Future<Room> joinByCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.length != kCodeLength) {
      throw AppException('초대 코드는 $kCodeLength자리예요.');
    }
    if (await _myRoomCount() >= kMaxRoomsPerUser) {
      throw AppException('방은 한 사람당 최대 $kMaxRoomsPerUser개까지 참여할 수 있어요.');
    }
    final c = await _db.collection('codes').doc(code).get();
    final roomId = c.data()?['roomId'] as String?;
    if (roomId == null) throw AppException('없는 코드예요. 다시 확인해 주세요.');
    final ref = _db.collection('rooms').doc(roomId);
    try {
      // 참여 전에는 방을 읽을 수 없어서, 읽지 않고 "나를 추가"만 요청해요.
      // 가득 찼거나 허락되지 않으면 서버 규칙이 거절해요.
      await ref.update({'members': FieldValue.arrayUnion([uid])});
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'not-found') {
        throw AppException('참여할 수 없는 방이에요. 가득 찼거나 코드가 바뀌었을 수 있어요.');
      }
      rethrow;
    }
    return Room.fromDoc(await ref.get());
  }

  /// 방장만. 이전 코드는 쓸 수 없게 돼요.
  Future<void> regenerateCode(Room room) async {
    if (room.ownerId != uid) throw AppException('방장만 코드를 다시 만들 수 있어요.');
    final code = await _freshCode();
    final batch = _db.batch();
    batch.delete(_db.collection('codes').doc(room.code));
    batch.set(_db.collection('codes').doc(code), {'roomId': room.id});
    batch.update(_db.collection('rooms').doc(room.id), {'code': code});
    await batch.commit();
  }

  Future<void> leaveRoom(Room room) async {
    final ref = _db.collection('rooms').doc(room.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final members = List<String>.from((snap.data()?['members'] as List?) ?? const []);
      members.remove(uid);
      if (members.isEmpty) {
        tx.delete(ref);
      } else {
        final owner = (snap.data()?['ownerId'] as String?) == uid ? members.first : null;
        tx.update(ref, {'members': members, if (owner != null) 'ownerId': owner});
      }
    });
  }
}

/// 화면에 보여 줄 오류 설명 (원인 파악용 코드 포함)
String errorDetail(Object e) {
  if (e is FirebaseException) return '${e.plugin}/${e.code}';
  return e.toString().split('\n').first;
}
