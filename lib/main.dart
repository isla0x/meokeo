import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

import 'data.dart';
import 'firebase_options.dart';
import 'notifications.dart';
import 'screens/nickname.dart';
import 'screens/root.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  runApp(const MeokeoApp());
  Notifier.instance.restore().catchError((_) {});
}

class MeokeoApp extends StatelessWidget {
  const MeokeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '뭐먹어?',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: kAccent,
        textTheme: CupertinoTextThemeData(
          textStyle: font(15, FontWeight.w500, letterSpacing: -0.2),
          navLargeTitleTextStyle: font(28, FontWeight.w700, letterSpacing: -0.4),
          navTitleTextStyle: font(16, FontWeight.w600),
          tabLabelTextStyle: font(10, FontWeight.w500, letterSpacing: -0.1),
        ),
      ),
      // 아이폰 설정의 글자 크기는 그대로 반영하면서 앱 전체 글자를 조금 키워요. (하루링과 같아요)
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scale = (mq.textScaler.scale(1.0) * kTextBoost).clamp(1.0, 1.6).toDouble();
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child!,
          ),
        );
      },
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
          return const CupertinoPageScaffold(child: Center(child: CupertinoActivityIndicator()));
        }
        if (snap.hasError) {
          return CupertinoPageScaffold(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('연결하지 못했어요.\n인터넷을 확인하고 다시 해 주세요.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(onPressed: _retry, child: const Text('다시 시도')),
                ]),
              ),
            ),
          );
        }
        final nick = snap.data;
        if (nick == null || nick.trim().isEmpty) {
          return NicknameScreen(onDone: _retry);
        }
        return const RootPage();
      },
    );
  }
}
