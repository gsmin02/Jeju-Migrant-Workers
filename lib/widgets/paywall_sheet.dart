import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
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
    final lang = context.watch<AppState>().lang;
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
          Text(tr(lang, 'pw_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tr(lang, 'pw_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(children: [
              const TextSpan(text: '\$3.50',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink)),
              TextSpan(text: ' ${tr(lang, 'pw_month')}',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ]),
          ),
          const SizedBox(height: 16),
          BigButton(tr(lang, 'pw_buy'), () {
            context.read<AppState>().buyPass();
            Navigator.pop(context);
            toast(context, tr(lang, 'pw_paid_toast'));
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6D3B8))),
            child: Text(tr(lang, 'pw_free_note'),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF7A4A17), height: 1.6)),
          ),
        ],
      ),
    );
  }
}
