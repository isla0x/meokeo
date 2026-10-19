// Firebase 클라이언트 설정값 (GoogleService-Info.plist의 공개용 값이에요. 비밀번호가 아니에요).
// 접근 제어는 Firestore/Storage 보안 규칙과 Google Cloud의 번들 ID 제한으로 해요.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyzyXniCZIGZhS5VJBXMLNelhua80G0Xs',
    appId: '1:158312063078:ios:2626233e209ffdb6ce0da7',
    messagingSenderId: '158312063078',
    projectId: 'meokeo-efa6e',
    storageBucket: 'meokeo-efa6e.firebasestorage.app',
    iosBundleId: 'com.isla0x.meokeo',
  );
}
