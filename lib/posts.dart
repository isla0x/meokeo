import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart' show Color, CupertinoIcons, IconData;

import 'ui.dart';

enum MealPhase { upcoming, now, past }

enum Meal {
  breakfast('아침', '🌅', 7 * 60, 9 * 60 + 30, CupertinoIcons.sunrise_fill, kSunrise),
  lunch('점심', '☀️', 11 * 60 + 30, 13 * 60, CupertinoIcons.sun_max_fill, kSun),
  dinner('저녁', '🌙', 17 * 60, 19 * 60, CupertinoIcons.moon_fill, kMoon);

  const Meal(this.label, this.emoji, this.fromMin, this.toMin, this.icon, this.color);
  final String label;
  final String emoji;
  final int fromMin;
  final int toMin;
  final IconData icon;
  final Color color;

  static String _c(int m, {bool period = true}) {
    final h = m ~/ 60, mi = m % 60;
    final per = h < 12 ? '오전' : '오후';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '${period ? '$per ' : ''}$h12:${mi.toString().padLeft(2, '0')}';
  }

  String get startLabel => _c(fromMin);

  String get window {
    final samePeriod = (fromMin ~/ 60 < 12) == (toMin ~/ 60 < 12);
    return '${_c(fromMin)} – ${_c(toMin, period: !samePeriod)}';
  }

  MealPhase phase(DateTime now) {
    final m = now.hour * 60 + now.minute;
    if (m < fromMin) return MealPhase.upcoming;
    if (m <= toMin) return MealPhase.now;
    return MealPhase.past;
  }

  /// 카메라 버튼으로 올릴 때 기본이 되는 끼니: 지금 열린 끼니 → 가장 최근에 시작한 끼니
  static Meal forCamera(DateTime now) {
    Meal pick = breakfast;
    for (final m in values) {
      if (m.phase(now) != MealPhase.upcoming) pick = m;
    }
    return pick;
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
    required this.at,
  });

  final String id;
  final String uid;
  final Meal meal;
  final String date;
  final Uint8List photo;
  final String text;
  final DateTime at;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Post(
      id: d.id,
      uid: m['uid'] as String,
      meal: Meal.values.firstWhere((x) => x.name == m['meal'], orElse: () => Meal.lunch),
      date: m['date'] as String,
      photo: _bytesOf(m['photo']),
      text: (m['text'] ?? '') as String,
      at: (m['createdAt'] is Timestamp) ? (m['createdAt'] as Timestamp).toDate() : DateTime.now(),
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
