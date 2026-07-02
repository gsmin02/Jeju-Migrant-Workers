import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../data/workplaces.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';

class WorkplaceTab extends StatefulWidget {
  const WorkplaceTab({super.key});

  @override
  State<WorkplaceTab> createState() => _WorkplaceTabState();
}

class _WorkplaceTabState extends State<WorkplaceTab> {
  String query = '';
  late Future<List<Workplace>> _future;

  @override
  void initState() {
    super.initState();
    _future = supabase.fetchWorkplaces();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
    final masked = app.masked;
    final q = query.trim().toLowerCase();

    return FutureBuilder<List<Workplace>>(
      future: _future,
      builder: (context, snap) {
        final all = snap.data ?? const <Workplace>[];
        final loading = snap.connectionState == ConnectionState.waiting;
        final filtered = q.isEmpty
            ? all
            : all
                .where((w) =>
                    w.name.toLowerCase().contains(q) ||
                    w.region.toLowerCase().contains(q) ||
                    w.job.toLowerCase().contains(q) ||
                    w.industry.toLowerCase().contains(q))
                .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            ViewHeader(tr(lang, 'work_title'), tr(lang, 'work_sub')),
            if (!app.previewPaid) _freeBadge(tr(lang, 'free_badge')),
            // 유료 전환 미리보기 토글
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(tr(lang, 'wp_preview'),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
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
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: tr(lang, 'work_search'),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: AppColors.line)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: AppColors.line)),
              ),
            ),
            if (app.workplace != null && app.workplace!.isNotEmpty && q.isEmpty) ...[
              SectionLabel(tr(lang, 'work_my')),
              _MyCard(lang: lang, name: app.workplace!),
            ],
            SectionLabel('${tr(lang, 'work_hiring')} · ${filtered.length}'),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.sea)),
              )
            else if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(tr(lang, 'work_none'),
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              )
            else
              for (final w in filtered)
                _WpCard(
                  wp: w,
                  lang: lang,
                  masked: masked && w.flagged,
                  onTapLocked: () => showPaywall(context),
                ),
            const SizedBox(height: 2),
            Text(tr(lang, 'wp_src'),
                style: const TextStyle(
                    fontSize: 9.5, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            BigButton(
              tr(lang, 'work_report_btn'),
              () => toast(context, tr(lang, 'work_report_toast')),
              sub: tr(lang, 'work_report_sub'),
              color: Colors.white,
            ),
          ],
        );
      },
    );
  }

  Widget _freeBadge(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.limeSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.limeDeep)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4A5D2A))),
      );
}

/// 내 사업장 카드 — 프로필에 등록한 사업장 이름을 보여준다.
class _MyCard extends StatelessWidget {
  const _MyCard({required this.lang, required this.name});
  final String lang;
  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(11)),
          alignment: Alignment.center,
          child: const Text('🏢', style: TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tr(lang, 'wp_mine_note'),
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.4)),
          ]),
        ),
        const SizedBox(width: 8),
        Pill(tr(lang, 'wp_clean'), bg: AppColors.greenSoft, fg: AppColors.green),
      ]),
    );
  }
}

/// jobploy 사업장 카드 (마스킹/페이월 연동).
class _WpCard extends StatelessWidget {
  const _WpCard({
    required this.wp,
    required this.lang,
    required this.masked,
    required this.onTapLocked,
  });

  final Workplace wp;
  final String lang;
  final bool masked;
  final VoidCallback onTapLocked;

  String _mask(String real) => real.replaceAllMapped(RegExp(r'[^\s·.]'), (_) => '?');

  @override
  Widget build(BuildContext context) {
    final stats = <List<String>>[
      if (wp.flagged)
        [masked ? '?건' : '${wp.reports}건', tr(lang, 'wp_report_cnt')]
      else
        ['0건', tr(lang, 'wp_reports')],
      ['${wp.workers}명', tr(lang, 'wp_workers')],
      if (wp.flagged)
        [masked ? '????' : (wp.lastReport ?? '-'), tr(lang, 'wp_recent')]
      else
        [wp.rating != null ? '★${wp.rating}' : '-', tr(lang, 'wp_rating')],
    ];

    final card = _WorkplaceCardShell(
      icon: wp.icon,
      iconBg: wp.flagged ? AppColors.redSoft : AppColors.seaSoft,
      name: masked ? _mask(wp.name) : wp.name,
      type: masked ? '${wp.industry} · ${_mask(wp.region)}' : '${wp.job} · ${wp.region}',
      pay: masked ? null : wp.pay,
      masked: masked,
      badge: wp.flagged
          ? Pill(tr(lang, 'wp_report'), bg: AppColors.redSoft, fg: AppColors.red)
          : Pill(tr(lang, 'wp_clean'), bg: AppColors.greenSoft, fg: AppColors.green),
      stats: stats,
      report: (wp.flagged && !masked) ? tr(lang, 'wp_report_note') : null,
      lockHint: masked ? tr(lang, 'wp_lockhint') : null,
    );
    return masked ? GestureDetector(onTap: onTapLocked, child: card) : card;
  }
}

/// 사업장 카드 공통 셸.
class _WorkplaceCardShell extends StatelessWidget {
  const _WorkplaceCardShell({
    required this.icon,
    required this.iconBg,
    required this.name,
    required this.type,
    required this.badge,
    required this.stats,
    this.pay,
    this.masked = false,
    this.report,
    this.lockHint,
  });

  final String icon;
  final Color iconBg;
  final String name;
  final String type;
  final Widget badge;
  final List<List<String>> stats;
  final String? pay;
  final bool masked;
  final String? report;
  final String? lockHint;

  @override
  Widget build(BuildContext context) {
    final maskColor = const Color(0xFFC4B795);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: kCardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: masked ? maskColor : AppColors.ink)),
              Text(type,
                  style: TextStyle(fontSize: 11, color: masked ? maskColor : AppColors.inkSoft)),
            ]),
          ),
          badge,
        ]),
        if (pay != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Text('💰 $pay',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.seaDeep)),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
            children: stats
                .map((s) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                            color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Text(s[0],
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: masked ? maskColor : AppColors.ink)),
                          const SizedBox(height: 1),
                          Text(s[1],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
                        ]),
                      ),
                    ))
                .toList()),
        if (report != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration:
                BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(9)),
            child: Text('⚠️ $report',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.4)),
          ),
        ],
        if (lockHint != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
                color: AppColors.seaSoft,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.sea)),
            child: Text(lockHint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.seaDeep)),
          ),
        ],
      ]),
    );
  }
}
