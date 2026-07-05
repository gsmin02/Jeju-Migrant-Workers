import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'state/i18n.dart';
import 'services/supabase_service.dart';
import 'screens/auth.dart';
import 'screens/tutorial.dart';
import 'screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await supabase.init(); // 실패해도 앱은 계속 (인증 화면 노출)
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const JejuPayApp()),
  );
}

class JejuPayApp extends StatelessWidget {
  const JejuPayApp({super.key});
  @override
  Widget build(BuildContext context) {
    // 언어 변경 시 브라우저 탭 제목(document.title)도 함께 갱신
    final lang = context.select<AppState, String>((s) => s.lang);
    return MaterialApp(
      title: tr(lang, 'app_title'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// 첫 실행: 튜토리얼(건너뛰기 없음) → 로그인 → 메인.
/// 로그인 세션이 있으면 바로 메인. 튜토리얼은 1회만(shared_preferences).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _prefKey = 'tutorial_seen_v1';
  bool? _tutorialSeen; // null = 로딩 중

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) setState(() => _tutorialSeen = prefs.getBool(_prefKey) ?? false);
    } catch (_) {
      if (mounted) setState(() => _tutorialSeen = false);
    }
  }

  Future<void> _finishTutorial() async {
    setState(() => _tutorialSeen = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_tutorialSeen == null) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator(color: AppColors.sea)),
      );
    }
    return StreamBuilder(
      stream: supabase.ready ? supabase.onAuthChange : const Stream.empty(),
      builder: (context, _) {
        if (supabase.isLoggedIn) return const MainShell();
        // 로그아웃/미로그인
        context.read<AppState>().resetForLogout();
        if (_tutorialSeen == false) {
          return TutorialScreen(onDone: _finishTutorial);
        }
        return const AuthScreen();
      },
    );
  }
}
