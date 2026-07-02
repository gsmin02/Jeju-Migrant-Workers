import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../services/supabase_service.dart';
import '../data/brand_svgs.dart';
import '../widgets/common.dart';

/// 로그인 / 회원가입 화면. 회원가입은 2단계(계정 → 사업지 등록). 로그인해야 앱 사용 가능.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool signupMode = false;
  int signupStep = 1; // 1=계정, 2=사업지 등록
  bool loading = false;
  String? error; // i18n 키 또는 Supabase 원문
  String? notice;

  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _name = TextEditingController();
  final _workplace = TextEditingController();
  final _tenure = TextEditingController();
  String? _nationality;

  static const _nationalities = [
    '네팔', '베트남', '인도네시아', '캄보디아', '스리랑카', '태국',
    '미얀마', '필리핀', '방글라데시', '몽골', '우즈베키스탄', '중국', '기타',
  ];

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _name.dispose();
    _workplace.dispose();
    _tenure.dispose();
    super.dispose();
  }

  bool _validAccount() {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => error = 'au_err_email');
      return false;
    }
    if (_pw.text.length < 6) {
      setState(() => error = 'au_err_pw');
      return false;
    }
    return true;
  }

  void _goStep2() {
    if (!_validAccount()) return;
    setState(() {
      error = null;
      signupStep = 2;
    });
  }

  Future<void> _submit() async {
    if (!signupMode && !_validAccount()) return;
    setState(() {
      loading = true;
      error = null;
      notice = null;
    });
    final err = signupMode
        ? await supabase.signUp(_email.text, _pw.text,
            name: _name.text.trim(),
            nationality: _nationality,
            workplace: _workplace.text.trim(),
            tenure: _tenure.text.trim())
        : await supabase.signIn(_email.text, _pw.text);
    if (!mounted) return;
    setState(() => loading = false);
    if (err != null) {
      setState(() {
        error = err;
        if (signupMode) signupStep = 1; // 오류 시 계정 단계로
      });
      return;
    }
    if (signupMode && !supabase.isLoggedIn) {
      setState(() {
        notice = 'au_notice';
        signupMode = false;
        signupStep = 1;
      });
    }
  }

  String _msg(String lang, String s) => kI18n['ko']!.containsKey(s) ? tr(lang, s) : s;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
    final worksite = signupMode && signupStep == 2;
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
                  child: SvgPicture.string(kBrandLogoSvg, width: 32, height: 32),
                ),
                const SizedBox(width: 10),
                const Text('제이', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
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
              if (signupMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('$signupStep / 2',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sea)),
                ),
              Text(
                worksite ? tr(lang, 'ws_title') : tr(lang, signupMode ? 'au_signup' : 'au_login'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                worksite
                    ? tr(lang, 'ws_sub')
                    : tr(lang, signupMode ? 'au_signup_sub' : 'au_login_sub'),
                style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 20),
              if (worksite) ...[
                _field(tr(lang, 'ws_name'), _workplace, hint: tr(lang, 'ws_name_hint')),
                _field(tr(lang, 'ws_tenure'), _tenure, hint: tr(lang, 'ws_tenure_hint')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
                  child: Text(tr(lang, 'ws_note'),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF5A4A2A), height: 1.5)),
                ),
              ] else ...[
                _field(tr(lang, 'au_email'), _email,
                    hint: tr(lang, 'au_email_hint'), keyboard: TextInputType.emailAddress),
                _field(tr(lang, 'au_pw'), _pw, hint: tr(lang, 'au_pw_hint'), obscure: true),
                if (signupMode) ...[
                  _field(tr(lang, 'au_name'), _name, hint: tr(lang, 'au_name_hint')),
                  _natField(lang),
                ],
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
                  : BigButton(
                      worksite
                          ? tr(lang, 'au_signup_btn')
                          : tr(lang, signupMode ? 'au_next' : 'au_login_btn'),
                      worksite ? _submit : (signupMode ? _goStep2 : _submit),
                    ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          if (worksite) {
                            _submit(); // 건너뛰기 = 사업지 없이 바로 가입
                            return;
                          }
                          setState(() {
                            signupMode = !signupMode;
                            signupStep = 1;
                            error = null;
                            notice = null;
                          });
                        },
                  child: Text(
                    worksite
                        ? tr(lang, 'au_skip')
                        : tr(lang, signupMode ? 'au_to_login' : 'au_to_signup'),
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
