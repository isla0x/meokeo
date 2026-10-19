import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';
import 'repo.dart';

/// 헷갈리는 글자(0/O, 1/I/L)를 뺀 초대 코드 글자들
const String _codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

Uint8List _bytesOf(dynamic v) {
  if (v is Blob) return v.bytes;
  if (v is Uint8List) return v;
  if (v is List) return Uint8List.fromList(v.cast<int>());
  return Uint8List(0);
}

Room _roomFrom(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data() ?? const <String, dynamic>{};
  final dots = <String, List<String>>{};
  final raw = m['dots'];
  if (raw is Map) {
    raw.forEach((k, v) {
      if (v is List) dots['$k'] = v.map((e) => '$e').toList();
    });
  }
  return Room(
    id: d.id,
    name: (m['name'] as String?) ?? '',
    icon: RoomIcon.parse(m['icon'] as String?),
    ownerId: (m['ownerId'] as String?) ?? '',
    members: List<String>.from((m['members'] as List?) ?? const []),
    code: (m['code'] as String?) ?? '',
    dots: dots,
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : null,
  );
}

Post _postFrom(DocumentSnapshot<Map<String, dynamic>> d) {
  final m = d.data()!;
  final ts = m['createdAt'];
  return Post(
    id: d.id,
    uid: m['uid'] as String,
    meal: Meal.values.firstWhere((x) => x.name == m['meal'], orElse: () => Meal.lunch),
    date: m['date'] as String,
    photo: _bytesOf(m['photo']),
    text: (m['text'] ?? '') as String,
    at: ts is Timestamp ? ts.toDate() : DateTime.now(),
  );
}

class FirebaseRepo extends Repo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, String> _nickCache = {};

  @override
  String get uid => _auth.currentUser!.uid;

  @override
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // ───────── 별명 ─────────
  @override
  Future<String?> myNickname() async {
    final d = await _db.collection('users').doc(uid).get();
    final n = d.data()?['nickname'] as String?;
    if (n != null) _nickCache[uid] = n;
    return n;
  }

  @override
  Future<void> setNickname(String nickname) async {
    final n = nickname.trim();
    await _db.collection('users').doc(uid).set(
      {'nickname': n, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    _nickCache[uid] = n;
  }

  @override
  Future<Map<String, String>> nicknames(Iterable<String> uids) async {
    final out = <String, String>{};
    for (final id in uids) {
      final cached = _nickCache[id];
      if (cached != null) {
        out[id] = cached;
        continue;
      }
      try {
        final d = await _db.collection('users').doc(id).get();
        final n = (d.data()?['nickname'] as String?) ?? '이름 없음';
        _nickCache[id] = n;
        out[id] = n;
      } catch (_) {
        out[id] = '이름 없음';
      }
    }
    return out;
  }

  // ───────── 방 ─────────
  @override
  Stream<List<Room>> myRooms() {
    return _db
        .collection('rooms')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(_roomFrom).toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.now();
        final tb = b.createdAt ?? DateTime.now();
        final c = ta.compareTo(tb);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      return list;
    });
  }

  Future<int> _myRoomCount() async {
    final s = await _db.collection('rooms').where('members', arrayContains: uid).count().get();
    return s.count ?? 0;
  }

  String _randomCode() {
    final r = Random.secure();
    return List.generate(kCodeLength, (_) => _codeChars[r.nextInt(_codeChars.length)]).join();
  }

  Future<String> _freshCode() async {
    for (var i = 0; i < 8; i++) {
      final c = _randomCode();
      final d = await _db.collection('codes').doc(c).get();
      if (!d.exists) return c;
    }
    throw AppException('코드를 만들지 못했어요. 잠시 뒤 다시 해 주세요.');
  }

  @override
  Future<Room> createRoom({required String name, required RoomIcon icon}) async {
    final n = name.trim();
    if (n.isEmpty) throw AppException('방 이름을 적어 주세요.');
    if (await _myRoomCount() >= kMaxRoomsPerUser) {
      throw AppException('방은 한 사람당 최대 $kMaxRoomsPerUser개까지 만들 수 있어요.');
    }
    final code = await _freshCode();
    final ref = _db.collection('rooms').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'name': n,
      'icon': icon.key,
      'ownerId': uid,
      'members': [uid],
      'code': code,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('codes').doc(code), {'roomId': ref.id});
    await batch.commit();
    return _roomFrom(await ref.get());
  }

  @override
  Future<Room> joinByCode(String rawCode) async {
    final code = rawCode.replaceAll('-', '').trim().toUpperCase();
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
    return _roomFrom(await ref.get());
  }

  @override
  Future<void> regenerateCode(Room room) async {
    if (room.ownerId != uid) throw AppException('방장만 코드를 다시 만들 수 있어요.');
    final code = await _freshCode();
    final batch = _db.batch();
    batch.delete(_db.collection('codes').doc(room.code));
    batch.set(_db.collection('codes').doc(code), {'roomId': room.id});
    batch.update(_db.collection('rooms').doc(room.id), {'code': code});
    await batch.commit();
  }

  @override
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

  // ───────── 사진 글 ─────────
  CollectionReference<Map<String, dynamic>> _posts(String roomId) =>
      _db.collection('rooms').doc(roomId).collection('posts');

  @override
  Stream<List<Post>> postsOn(String roomId, String date) {
    return _posts(roomId).where('date', isEqualTo: date).snapshots().map((s) {
      final list = s.docs.map(_postFrom).toList();
      list.sort((a, b) => a.meal.index.compareTo(b.meal.index));
      return list;
    });
  }

  /// 같은 날 같은 끼니는 한 사람당 한 개. 다시 올리면 덮어써요.
  @override
  Future<void> uploadPost({
    required String roomId,
    required Meal meal,
    required DateTime day,
    required Uint8List photo,
    String text = '',
  }) async {
    if (photo.length > kMaxPhotoBytes) throw AppException('사진이 너무 커요. 다른 사진으로 해 주세요.');
    final date = dayKey(day);
    final id = '${date}_${meal.name}_$uid';
    await _posts(roomId).doc(id).set({
      'uid': uid,
      'meal': meal.name,
      'date': date,
      'photo': Blob(photo),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // 캘린더 점: 방 문서에 "그날 올라온 끼니"를 적어 둬요. (사진을 다 불러오지 않고도 점을 그릴 수 있어요)
    try {
      await _db.collection('rooms').doc(roomId).update({
        'dots.$date': FieldValue.arrayUnion([meal.name]),
      });
    } catch (_) {}
  }

  @override
  Future<void> deletePost(String roomId, Post post) async {
    await _posts(roomId).doc(post.id).delete();
  }
}

/// 화면에 보여 줄 오류 설명 (원인 파악용 코드 포함)
String errorDetail(Object e) {
  if (e is FirebaseException) return '${e.plugin}/${e.code}';
  return e.toString().split('\n').first;
}
