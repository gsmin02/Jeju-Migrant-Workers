import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';

class WorkplaceTab extends StatelessWidget {
  const WorkplaceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final masked = app.masked;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        ViewHeader(tr(app.lang, 'work_title'), tr(app.lang, 'work_sub')),
        if (!app.previewPaid)
          _freeBadge(tr(app.lang, 'free_badge')),
        // 유료 전환 미리보기 토글
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('👁 유료 전환 후 모습 미리보기 ',
              style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
          Transform.scale(
            scale: .8,
            child: Switch(
              value: app.previewPaid,
              activeThumbColor: AppColors.sea,
              onChanged: (v) => app.setPreviewPaid(v),
            ),
          ),
        ]),
        TextField(
          decoration: InputDecoration(
            hintText: '🔍 사업장 이름으로 검색',
            isDense: true,
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: AppColors.line)),
          ),
        ),
        const SizedBox(height: 12),
        const SectionLabel('내 사업장'),
        _wpCard(
          icon: '🐟', iconBg: AppColors.seaSoft, name: '한라양식',
          type: '양식장 · 서귀포시 성산읍', clean: true,
          stats: const [['1년 2개월', '내 근속'], ['6명', '이용 노동자'], ['0건', '누적 신고']],
        ),
        const SectionLabel('최근 조회한 곳'),
        _wpCard(
          icon: '🍊', iconBg: AppColors.redSoft,
          name: masked ? '?????농원' : '○○감귤농원',
          type: masked ? '농업 · ???시 ??읍' : '농업 · 서귀포시 남원읍',
          warn: true, masked: masked, onTapLocked: () => showPaywall(context),
          stats: [
            [masked ? '?건' : '3건', '임금체불 신고'],
            [masked ? '?명' : '8명', '이용 노동자'],
            [masked ? '????' : '2025', '최근 신고'],
          ],
          report: '신고 내역은 노동자들의 익명 제보 집계입니다. 사실 확인 전 정보이며, 참고용으로만 활용하세요.',
        ),
        _wpCard(
          icon: '🏭', iconBg: AppColors.greenSoft,
          name: masked ? '???수산??' : '△△수산가공',
          type: masked ? '제조 · ??시 ??읍' : '제조 · 제주시 한림읍',
          clean: true, masked: masked, onTapLocked: () => showPaywall(context),
          stats: [
            [masked ? '?건' : '0건', '누적 신고'],
            [masked ? '??명' : '12명', '이용 노동자'],
            [masked ? '★?.?' : '★4.2', '근로 평가'],
          ],
        ),
        const SizedBox(height: 6),
        BigButton('🚩 임금체불 사업장 신고하기',
            () => toast(context, '🚩 임금체불 신고 접수 (익명·비공개로 처리)'),
            sub: '익명으로 접수되며, 다른 노동자에게 경고가 됩니다', color: Colors.white),
      ],
    );
  }

  Widget _freeBadge(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.limeSoft, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.limeDeep)),
        child: Text(text,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4A5D2A))),
      );

  Widget _wpCard({
    required String icon, required Color iconBg, required String name, required String type,
    bool clean = false, bool warn = false, bool masked = false,
    required List<List<String>> stats, String? report, VoidCallback? onTapLocked,
  }) {
    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line), boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center, child: Text(icon, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800,
                  color: masked ? const Color(0xFFC4B795) : AppColors.ink)),
              Text(type, style: TextStyle(fontSize: 11,
                  color: masked ? const Color(0xFFC4B795) : AppColors.inkSoft)),
            ]),
          ),
          if (clean) Pill('✓ 신고 없음', bg: AppColors.greenSoft, fg: AppColors.green),
          if (warn) Pill('⚠ 신고 있음', bg: AppColors.redSoft, fg: AppColors.red),
        ]),
        const SizedBox(height: 12),
        Row(children: stats.map((s) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(s[0], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: masked ? const Color(0xFFC4B795) : AppColors.ink)),
              const SizedBox(height: 1),
              Text(s[1], textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
            ]),
          ),
        )).toList()),
        if (report != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(9)),
            child: Text('⚠️ $report',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.4)),
          ),
        ],
        if (masked) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
                color: AppColors.seaSoft, borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.sea)),
            child: const Text('🔒 사업장 이름·세부 내용은 이용권 구매 후 볼 수 있어요 · 눌러서 구매',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.seaDeep)),
          ),
        ],
      ]),
    );
    if (masked && onTapLocked != null) {
      return GestureDetector(onTap: onTapLocked, child: card);
    }
    return card;
  }
}
