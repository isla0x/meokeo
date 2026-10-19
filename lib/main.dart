import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  runApp(const MeokeoApp());
}

/// 뭐먹어? — 첫 뼈대. 목업(9개 화면)을 기준으로 하나씩 채워 나가요.
class MeokeoApp extends StatelessWidget {
  const MeokeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뭐먹어?',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE8658A),
        scaffoldBackgroundColor: const Color(0xFFF7F7F9),
      ),
      home: const Scaffold(body: Center(child: Text('뭐먹어?'))),
    );
  }
}
