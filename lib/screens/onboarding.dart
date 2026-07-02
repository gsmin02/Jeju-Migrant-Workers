import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

/// 온보딩 공통 입력 필드
Widget _field(String label, String hint, {bool obscure = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
        ),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true, fillColor: Colors.white,
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

class SignupScreen extends StatelessWidget {
  final VoidCallback onNext, onSkip;
  const SignupScreen({super.key, required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1 / 2',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sea)),
              const SizedBox(height: 6),
              const Text('회원가입',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('간단한 정보만 입력하면 시작할 수 있어요.\n입력한 정보는 안전하게 보관돼요.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 18),
              _SocialButton('G  Google로 계속하기', Colors.white, AppColors.ink, onNext),
              const SizedBox(height: 9),
              _SocialButton('  Apple로 계속하기', const Color(0xFF111111), Colors.white, onNext),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider(color: AppColors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('또는 직접 입력',
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                ),
                const Expanded(child: Divider(color: AppColors.line)),
              ]),
              _field('이름 (닉네임도 괜찮아요)', '예: Bibek / 비벡'),
              _field('국적', '네팔'),
              _field('휴대폰 번호', '010-0000-0000'),
              _field('비밀번호', '••••••', obscure: true),
              const SizedBox(height: 20),
              BigButton('다음', onNext),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('건너뛰기',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorksiteScreen extends StatelessWidget {
  final VoidCallback onDone;
  const WorksiteScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('2 / 2',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sea)),
              const SizedBox(height: 6),
              const Text('사업지 등록',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('지금 일하는 곳을 등록하면,\nGPS 근무 기록과 임금체불 신고 이력을 볼 수 있어요.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 12),
              _field('사업장 이름', '예: 한라양식'),
              _field('업종', '양식장 (어업)'),
              _field('지역 (읍·면·동)', '예: 서귀포시 성산읍'),
              _field('입사일 (근속 계산용)', '예: 2025-05'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  app.setJobAd('채용공고.jpg');
                  toast(context, '📸 채용공고 저장됨 — 근로조건 입증 자료로 보관돼요');
                },
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
                  child: const Text(
                      '📎 채용공고 사진 (선택 — 계약서가 없을 때 근로조건을 입증하는 자료가 돼요)',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF5A4A2A), height: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              BigButton('등록하고 시작하기', onDone),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: onDone,
                  child: const Text('나중에 등록할게요',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _SocialButton(this.label, this.bg, this.fg, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bg == Colors.white ? AppColors.line : bg, width: 1.5)),
            child: Text(label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
          ),
        ),
      );
}
