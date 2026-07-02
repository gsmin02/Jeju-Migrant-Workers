import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'services/supabase_service.dart';
import 'screens/splash_language.dart';
import 'screens/onboarding.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await supabase.init(); // 실패해도 앱은 계속 (폴백)
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const JejuPayApp()),
  );
}

/// 온보딩 단계
enum AppStage { splash, signup, worksite, main }

class JejuPayApp extends StatefulWidget {
  const JejuPayApp({super.key});
  @override
  State<JejuPayApp> createState() => _JejuPayAppState();
}

class _JejuPayAppState extends State<JejuPayApp> {
  // 기본 splash. 검증용으로 --dart-define=START=main 지정 가능.
  AppStage stage = const String.fromEnvironment('START') == 'main'
      ? AppStage.main
      : AppStage.splash;
  void go(AppStage s) => setState(() => stage = s);

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (stage) {
      case AppStage.splash:
        body = SplashLanguageScreen(onPicked: () => go(AppStage.signup));
        break;
      case AppStage.signup:
        body = SignupScreen(
          onNext: () => go(AppStage.worksite),
          onSkip: () => go(AppStage.main),
        );
        break;
      case AppStage.worksite:
        body = WorksiteScreen(onDone: () => go(AppStage.main));
        break;
      case AppStage.main:
        body = const MainShell();
        break;
    }
    return MaterialApp(
      title: 'Jeju Migrant Workers',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: body,
    );
  }
}
