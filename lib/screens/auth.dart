import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';
import '../widgets/citrus_mark.dart';

/// 로그인 / 회원가입 화면. 로그인해야만 앱을 쓸 수 있다(건너뛰기 없음).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signupMode = false;
  bool loading = false;
  String? error;
  String? notice;

  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _name = TextEditingController();
  String? _nationality; // 고정 목록에서 선택

  // 제주 이주노동자 주요 국적 (스크롤 선택 목록)
  static const _nationalities = [
    '네팔', '베트남', '인도네시아', '캄보디아', '스리랑카', '태국',
    '미얀마', '필리핀', '방글라데시', '몽골', '우즈베키스탄', '중국', '기타',
  ];

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pw = _pw.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => error = '올바른 이메일을 입력해 주세요.');
      return;
    }
    if (pw.length < 6) {
      setState(() => error = '비밀번호는 6자 이상이어야 해요.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      notice = null;
    });
    final err = signupMode
        ? await supabase.signUp(email, pw,
            name: _name.text.trim(), nationality: _nationality)
        : await supabase.signIn(email, pw);
    if (!mounted) return;
    setState(() => loading = false);
    if (err != null) {
      setState(() => error = err);
      return;
    }
    // 성공: 로그인 세션이 생기면 AuthGate(StreamBuilder)가 자동으로 메인으로 전환.
    // 회원가입인데 세션이 아직 없으면(이메일 인증 필요 설정) 안내.
    if (signupMode && !supabase.isLoggedIn) {
      setState(() {
        notice = '가입 완료! 이메일 인증이 필요한 설정이면 메일함을 확인한 뒤 로그인해 주세요.';
        signupMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
                  child: const CitrusMark(size: 32),
                ),
                const SizedBox(width: 10),
                const Text('제이',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 22),
              Text(signupMode ? '회원가입' : '로그인',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                signupMode
                    ? '이메일과 비밀번호로 계정을 만들어 주세요.\n근무 기록은 안전하게 내 계정에만 저장돼요.'
                    : '가입한 이메일로 로그인하면 내 근무 기록을 볼 수 있어요.',
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 20),
              _field('이메일', _email, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
              _field('비밀번호', _pw, hint: '6자 이상', obscure: true),
              if (signupMode) ...[
                _field('이름 (닉네임도 괜찮아요)', _name, hint: '예: Bibek / 비벡'),
                _natField(),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                _banner(error!, AppColors.redSoft, AppColors.red),
              ],
              if (notice != null) ...[
                const SizedBox(height: 12),
                _banner(notice!, AppColors.limeSoft, const Color(0xFF4A5D2A)),
              ],
              const SizedBox(height: 22),
              loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(color: AppColors.sea),
                      ),
                    )
                  : BigButton(signupMode ? '가입하고 시작하기' : '로그인', _submit),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () => setState(() {
                            signupMode = !signupMode;
                            error = null;
                            notice = null;
                          }),
                  child: Text(
                    signupMode ? '이미 계정이 있어요 · 로그인' : '계정이 없어요 · 회원가입',
                    style: const TextStyle(color: AppColors.seaDeep, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, Color bg, Color fg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 12, color: fg, height: 1.4, fontWeight: FontWeight.w600)),
      );

  // 국적: 자유입력 대신 고정 목록에서 선택 (목록이 길면 스크롤).
  Widget _natField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 4),
            child: Text('국적 (선택)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          DropdownButtonFormField<String>(
            initialValue: _nationality,
            isExpanded: true,
            menuMaxHeight: 320,
            icon: const Icon(Icons.expand_more, color: AppColors.inkSoft),
            hint: const Text('국적을 선택하세요',
                style: TextStyle(color: Color(0xFFB0A98F), fontSize: 14)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sea, width: 1.5)),
            ),
            items: [
              for (final n in _nationalities)
                DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 14))),
            ],
            onChanged: (v) => setState(() => _nationality = v),
          ),
        ],
      );

  Widget _field(String label, TextEditingController c,
          {String? hint, bool obscure = false, TextInputType? keyboard}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          TextField(
            controller: c,
            obscureText: obscure,
            keyboardType: keyboard,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.sea, width: 1.5)),
            ),
          ),
        ],
      );
}
