import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum Meal {
  breakfast('아침', '🌅', 5, 10),
  lunch('점심', '☀️', 11, 15),
  dinner('저녁', '🌙', 17, 22);

  const Meal(this.label, this.emoji, this.fromHour, this.toHour);
  final String label;
  final String emoji;
  final int fromHour;
  final int toHour;

  String get window => '$fromHour:00 – $toHour:00';

  /// 지금 시각에 가까운 끼니
  static Meal nearest(DateTime now) {
    final h = now.hour;
    if (h < 11) return breakfast;
    if (h < 16) return lunch;
    return dinner;
  }
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Uint8List _bytesOf(dynamic v) {
  if (v is Blob) return v.bytes;
  if (v is Uint8List) return v;
  if (v is List) return Uint8List.fromList(v.cast<int>());
  return Uint8List(0);
}

class Post {
  Post({
    required this.id,
    required this.uid,
    required this.meal,
    required this.date,
    required this.photo,
    required this.text,
  });

  final String id;
  final String uid;
  final Meal meal;
  final String date;
  final Uint8List photo;
  final String text;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Post(
      id: d.id,
      uid: m['uid'] as String,
      meal: Meal.values.firstWhere((x) => x.name == m['meal'], orElse: () => Meal.lunch),
      date: m['date'] as String,
      photo: _bytesOf(m['photo']),
      text: (m['text'] ?? '') as String,
    );
  }
}

class PostRepo {
  PostRepo._();
  static final instance = PostRepo._();

  final _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _col(String roomId) =>
      _db.collection('rooms').doc(roomId).collection('posts');

  Stream<List<Post>> postsOn(String roomId, String date) {
    return _col(roomId).where('date', isEqualTo: date).snapshots().map((s) {
      final list = s.docs.map(Post.fromDoc).toList();
      list.sort((a, b) => a.meal.index.compareTo(b.meal.index));
      return list;
    });
  }

  Stream<List<Post>> postsInMonth(String roomId, DateTime month) {
    final a = dayKey(DateTime(month.year, month.month, 1));
    final b = dayKey(DateTime(month.year, month.month + 1, 1));
    return _col(roomId)
        .where('date', isGreaterThanOrEqualTo: a)
        .where('date', isLessThan: b)
        .snapshots()
        .map((s) => s.docs.map(Post.fromDoc).toList());
  }

  /// 같은 날 같은 끼니는 한 사람당 한 개. 다시 올리면 덮어써요.
  Future<void> upload({
    required String roomId,
    required Meal meal,
    required DateTime day,
    required File photo,
    String text = '',
  }) async {
    final date = dayKey(day);
    final id = '${date}_${meal.name}_$uid';
    final bytes = await photo.readAsBytes();
    if (bytes.length > 700 * 1024) {
      throw Exception('too-large');
    }
    await _col(roomId).doc(id).set({
      'uid': uid,
      'meal': meal.name,
      'date': date,
      'photo': Blob(bytes),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String roomId, Post p) async {
    await _col(roomId).doc(p.id).delete();
  }
}
