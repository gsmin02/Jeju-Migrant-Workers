import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state/app_state.dart';
import 'services/supabase_service.dart';
import 'screens/auth.dart';
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
    return MaterialApp(
      title: 'Jeju Migrant Workers',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}

/// 로그인 세션이 있을 때만 메인을 보여준다. 없으면 로그인/회원가입 화면.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (!supabase.ready) return const AuthScreen(); // 초기화 실패 시에도 인증부터
    return StreamBuilder(
      stream: supabase.onAuthChange,
      builder: (context, _) {
        if (supabase.isLoggedIn) return const MainShell();
        // 로그아웃 상태면 로드 플래그 초기화
        context.read<AppState>().resetForLogout();
        return const AuthScreen();
      },
    );
  }
}
