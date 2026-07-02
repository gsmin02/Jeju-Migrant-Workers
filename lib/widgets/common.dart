import 'package:flutter/material.dart';
import '../theme.dart';

/// 목업 .card — 흰 배경 + 라인 + 그림자 둥근 상자
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? border;
  const AppCard({super.key, required this.child, this.padding, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border ?? AppColors.line),
        boxShadow: kCardShadow,
      ),
      child: child,
    );
  }
}

/// 섹션 라벨 (대문자 소형 헤더)
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 9),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
                letterSpacing: .3)),
      );
}

/// 뷰 제목 + 부제
class ViewHeader extends StatelessWidget {
  final String title, sub;
  const ViewHeader(this.title, this.sub, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.3)),
          const SizedBox(height: 3),
          Text(sub,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.4)),
          const SizedBox(height: 14),
        ],
      );
}

/// 알약 뱃지
class Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Pill(this.text, {super.key, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
      );
}

/// 토스트(스낵바) 헬퍼
void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
    backgroundColor: AppColors.navyDeep,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    margin: const EdgeInsets.fromLTRB(40, 0, 40, 90),
    duration: const Duration(milliseconds: 2200),
  ));
}

/// 큰 CTA 버튼
class BigButton extends StatelessWidget {
  final String label;
  final String? sub;
  final VoidCallback onTap;
  final Color color;
  const BigButton(this.label, this.onTap,
      {super.key, this.sub, this.color = AppColors.sea});
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              if (sub != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(sub!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500)),
                ),
            ]),
          ),
        ),
      );
}
