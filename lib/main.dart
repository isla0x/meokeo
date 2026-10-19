import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'repo/firebase_repo.dart';
import 'repo/repo.dart';
import 'screens/nickname.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.ios);
  Repo.instance = FirebaseRepo();
  final state = AppState(Repo.instance);
  runApp(MeokeoApp(state: state));
  unawaited(state.boot());
}

class MeokeoApp extends StatelessWidget {
  const MeokeoApp({super.key, required this.state, this.home});
  final AppState state;

  /// 화면 확인용: 첫 화면을 직접 지정해요 (비워 두면 로그인 상태에 따라 정해져요)
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: CupertinoApp(
        title: '뭐먹어?',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        theme: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: C.teal,
          scaffoldBackgroundColor: C.bg,
        ),
        builder: (context, child) {
          // 아이폰 설정의 글자 크기는 따르되, 화면이 깨지지 않게 최대 1.3배까지만
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3)),
            child: DefaultTextStyle(style: ts(15, color: C.black), child: child!),
          );
        },
        home: home ?? const Gate(),
      ),
    );
  }
}

/// 로그인(익명) → 이름이 없으면 이름 정하기 → 홈
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.bootError != null) {
      return CupertinoPageScaffold(
        backgroundColor: C.bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
          child: Column(children: [
            const Spacer(),
            const AppMark(size: 72),
            const SizedBox(height: 20),
            Text('연결하지 못했어요', style: ts(20, w: FontWeight.w700, lh: 25)),
            const SizedBox(height: 4),
            Text('인터넷을 확인하고 다시 해 주세요', style: ts(15, lh: 20, color: C.sub)),
            const Spacer(),
            CtaButton(label: '다시 해 보기', onTap: () => unawaited(app.boot())),
          ]),
        ),
      );
    }
    if (!app.booted) {
      return const CupertinoPageScaffold(
        backgroundColor: C.bg,
        child: Center(child: AppMark(size: 88)),
      );
    }
    if (!app.hasNickname) return const NicknamePage();
    return const Shell();
  }
}
