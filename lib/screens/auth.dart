import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
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
  String? error; // 원문 메시지(Supabase) 또는 i18n 키
  String? notice; // i18n 키

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
      setState(() => error = 'au_err_email');
      return;
    }
    if (pw.length < 6) {
      setState(() => error = 'au_err_pw');
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
    if (signupMode && !supabase.isLoggedIn) {
      setState(() {
        notice = 'au_notice';
        signupMode = false;
      });
    }
  }

  /// 오류 문자열이 i18n 키면 번역, 아니면(Supabase 원문 메시지) 그대로.
  String _msg(String lang, String s) => kI18n['ko']!.containsKey(s) ? tr(lang, s) : s;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
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
                const Spacer(),
                // 언어 전환 (로그인 전에도 모국어로)
                GestureDetector(
                  onTap: () => context.read<AppState>().cycleLang(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.line, width: 1.5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('🌐 ${AppState.langLabels[lang]}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.seaDeep)),
                  ),
                ),
              ]),
              const SizedBox(height: 22),
              Text(tr(lang, signupMode ? 'au_signup' : 'au_login'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                tr(lang, signupMode ? 'au_signup_sub' : 'au_login_sub'),
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 20),
              _field(tr(lang, 'au_email'), _email,
                  hint: tr(lang, 'au_email_hint'), keyboard: TextInputType.emailAddress),
              _field(tr(lang, 'au_pw'), _pw, hint: tr(lang, 'au_pw_hint'), obscure: true),
              if (signupMode) ...[
                _field(tr(lang, 'au_name'), _name, hint: tr(lang, 'au_name_hint')),
                _natField(lang),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                _banner(_msg(lang, error!), AppColors.redSoft, AppColors.red),
              ],
              if (notice != null) ...[
                const SizedBox(height: 12),
                _banner(_msg(lang, notice!), AppColors.limeSoft, const Color(0xFF4A5D2A)),
              ],
              const SizedBox(height: 22),
              loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(color: AppColors.sea),
                      ),
                    )
                  : BigButton(tr(lang, signupMode ? 'au_signup_btn' : 'au_login_btn'), _submit),
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
                    tr(lang, signupMode ? 'au_to_login' : 'au_to_signup'),
                    style: const TextStyle(
                        color: AppColors.seaDeep, fontSize: 13, fontWeight: FontWeight.w700),
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
        child: Text(text,
            style: TextStyle(fontSize: 12, color: fg, height: 1.4, fontWeight: FontWeight.w600)),
      );

  // 국적: 자유입력 대신 고정 목록에서 선택 (목록이 길면 스크롤).
  Widget _natField(String lang) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(tr(lang, 'au_nat'),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          DropdownButtonFormField<String>(
            initialValue: _nationality,
            isExpanded: true,
            menuMaxHeight: 320,
            icon: const Icon(Icons.expand_more, color: AppColors.inkSoft),
            hint: Text(tr(lang, 'au_nat_hint'),
                style: const TextStyle(color: Color(0xFFB0A98F), fontSize: 14)),
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
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
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
