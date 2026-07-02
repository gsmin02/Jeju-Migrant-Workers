import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import 'common.dart';

/// 페이월 → 결제 시트. 구매 시 app.buyPass().
void showPaywall(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => const _PaywallSheet(),
  );
}

class _PaywallSheet extends StatelessWidget {
  const _PaywallSheet();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 42, height: 5, decoration: BoxDecoration(
              color: AppColors.line, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          const Text('🔒', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          const Text('글쓰기·사업장 상세 열람',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              '커뮤니티 글 읽기는 무료예요. 글을 쓰거나, 신고된 사업장의 이름·세부 내용을 보려면 이용권이 필요해요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(children: [
              TextSpan(text: '\$3.50',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink)),
              TextSpan(text: ' / 1개월',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(height: 16),
          BigButton('이용권 구매하기', () {
            context.read<AppState>().buyPass();
            Navigator.pop(context);
            toast(context, '결제 완료 · 잠금 해제 (데모)');
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6D3B8))),
            child: const Text(
                '⚠️ 오픈 기간에는 전 기능이 무료입니다. 유료 전환은 사용자 확보 후 진행돼요.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF7A4A17), height: 1.6)),
          ),
        ],
      ),
    );
  }
}
