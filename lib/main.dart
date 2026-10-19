import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/nickname.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  runApp(const MeokeoApp());
}

class MeokeoApp extends StatelessWidget {
  const MeokeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뭐먹어?',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Gate(),
    );
  }
}

/// 로그인(익명) → 별명이 없으면 별명 정하기 → 홈
class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late Future<String?> _boot;

  @override
  void initState() {
    super.initState();
    _boot = _start();
  }

  Future<String?> _start() async {
    await Repo.instance.ensureSignedIn();
    return Repo.instance.myNickname();
  }

  void _retry() => setState(() => _boot = _start());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('연결하지 못했어요.\n인터넷을 확인하고 다시 해 주세요.', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('다시 시도')),
                  ],
                ),
              ),
            ),
          );
        }
        final nick = snap.data;
        if (nick == null || nick.trim().isEmpty) {
          return NicknameScreen(onDone: _retry);
        }
        return const HomeScreen();
      },
    );
  }
}
