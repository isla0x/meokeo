import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

class Post {
  Post({
    required this.id,
    required this.uid,
    required this.meal,
    required this.date,
    required this.photoUrl,
    required this.text,
  });

  final String id;
  final String uid;
  final Meal meal;
  final String date;
  final String photoUrl;
  final String text;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Post(
      id: d.id,
      uid: m['uid'] as String,
      meal: Meal.values.firstWhere((x) => x.name == m['meal'], orElse: () => Meal.lunch),
      date: m['date'] as String,
      photoUrl: (m['photoUrl'] ?? '') as String,
      text: (m['text'] ?? '') as String,
    );
  }
}

class PostRepo {
  PostRepo._();
  static final instance = PostRepo._();

  final _db = FirebaseFirestore.instance;
  final _st = FirebaseStorage.instance;
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
    final ref = _st.ref('meals/$roomId/$id.jpg');
    await ref.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _col(roomId).doc(id).set({
      'uid': uid,
      'meal': meal.name,
      'date': date,
      'photoUrl': url,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String roomId, Post p) async {
    await _col(roomId).doc(p.id).delete();
    try {
      await _st.ref('meals/$roomId/${p.id}.jpg').delete();
    } catch (_) {}
  }
}
