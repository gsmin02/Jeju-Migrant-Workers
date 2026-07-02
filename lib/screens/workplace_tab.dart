import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../data/workplaces.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';
import '../widgets/complaint_sheet.dart';
import '../widgets/reminder_sheet.dart';

/// 사업장 탭 (v21):
/// - 내 사업장 카드 (근속·동료·급여일)
/// - 제주 채용 사업장 목록 (급여/고용형태 + 이용노동자/근로평가/누적신고, 신고 건수 그대로 노출)
/// - "혹시 임금 문제가 생기면" 2단계 플로우: ① 비공개 임금 리마인더 → ② 신고
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

  static const _freeLimit = 3;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
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

        final showLock = !app.paid && filtered.length > _freeLimit;
        final shown = app.paid ? filtered : filtered.take(_freeLimit).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            ViewHeader(tr(lang, 'work_title'), tr(lang, 'work_sub')),
            // 검색은 이용권(paid) 사용자만. 미결제 시 눌러서 페이월.
            if (app.paid)
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
              )
            else
              GestureDetector(
                onTap: () => showPaywall(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F1E6),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lock_outline, size: 16, color: AppColors.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tr(lang, 'wp_search_lock'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 4),
            if (app.workplace != null && app.workplace!.isNotEmpty && q.isEmpty) ...[
              SectionLabel(tr(lang, 'work_my')),
              _MyCard(lang: lang, name: app.workplace!),
            ],
            SectionLabel(tr(lang, 'wp_sec_browse')),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              child: Text(tr(lang, 'wp_browse_sub'),
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.45)),
            ),
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
            else ...[
              for (final w in shown) _WpCard(wp: w, lang: lang),
              if (showLock) _WorkLock(lang: lang),
            ],
            const SizedBox(height: 2),
            Text(tr(lang, 'wp_src_note'),
                style: const TextStyle(
                    fontSize: 9.5, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
            if (q.isEmpty) ...[
              SectionLabel(tr(lang, 'wp_help_sec')),
              _HelpSteps(lang: lang),
            ],
          ],
        );
      },
    );
  }
}

// ---------- 통계 박스 ----------
class _StatBox extends StatelessWidget {
  const _StatBox(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration:
              BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
          ]),
        ),
      );
}

Widget _statRow(List<Widget> boxes) {
  final children = <Widget>[];
  for (var i = 0; i < boxes.length; i++) {
    children.add(boxes[i]);
    if (i != boxes.length - 1) children.add(const SizedBox(width: 8));
  }
  return Row(children: children);
}

// ---------- 내 사업장 카드 ----------
class _MyCard extends StatelessWidget {
  const _MyCard({required this.lang, required this.name});
  final String lang;
  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: const Text('🐟', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text(tr(lang, 'wp_mine_type'),
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ]),
          ),
          Pill(tr(lang, 'wp_working'), bg: AppColors.greenSoft, fg: AppColors.green),
        ]),
        const SizedBox(height: 12),
        _statRow([
          _StatBox(tr(lang, 'p_tenure_v'), tr(lang, 'wp_tenure')),
          _StatBox('6${tr(lang, 'unit_persons')}', tr(lang, 'wp_coworkers')),
          _StatBox(tr(lang, 'wp_payday_v'), tr(lang, 'wp_payday')),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration:
              BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(10)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🍊', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(tr(lang, 'wp_mine_note'),
                  style: const TextStyle(
                      fontSize: 11.5, color: Color(0xFF3A4A55), height: 1.5)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ---------- 채용 사업장 카드 ----------
class _WpCard extends StatelessWidget {
  const _WpCard({required this.wp, required this.lang});
  final Workplace wp;
  final String lang;

  bool get _trusted => !wp.flagged && wp.rating != null && wp.rating! >= 4.8;

  @override
  Widget build(BuildContext context) {
    final ({String text, Color bg, Color fg}) badge = wp.flagged
        ? (
            text: tr(lang, 'wp_report_n').replaceAll('{n}', '${wp.reports}'),
            bg: AppColors.redSoft,
            fg: AppColors.red
          )
        : _trusted
            ? (text: tr(lang, 'wp_trust'), bg: AppColors.limeSoft, fg: AppColors.limeDeep)
            : (text: tr(lang, 'wp_clean'), bg: AppColors.greenSoft, fg: AppColors.green);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: wp.flagged ? AppColors.redSoft : AppColors.seaSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(wp.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(wp.name,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text('${wp.job} · ${wp.region}',
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
            ]),
          ),
          Pill(badge.text, bg: badge.bg, fg: badge.fg),
        ]),
        const SizedBox(height: 11),
        // 급여 · 고용형태
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(children: [
            _DetailRow(
                label: tr(lang, 'wp_wage_l'),
                value: _localizedPay(lang, wp.pay),
                strong: true),
            const Divider(height: 1, color: AppColors.line),
            _DetailRow(label: tr(lang, 'wp_emp_l'), value: tr(lang, 'wp_emp_v')),
          ]),
        ),
        const SizedBox(height: 10),
        _statRow([
          _StatBox('${wp.workers}${tr(lang, 'unit_persons')}', tr(lang, 'wp_workers')),
          _StatBox(wp.rating != null ? '★${wp.rating}' : '-', tr(lang, 'wp_rating')),
          _StatBox('${wp.reports}${tr(lang, 'unit_case')}', tr(lang, 'wp_reports')),
        ]),
        if (wp.flagged) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration:
                BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(9)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚠️', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(tr(lang, 'wp_report_note'),
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.45)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: strong ? 12.5 : 12,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  color: strong ? AppColors.seaDeep : AppColors.ink)),
        ]),
      );
}

// ---------- 임금 문제 2단계 플로우 ----------
class _HelpSteps extends StatelessWidget {
  const _HelpSteps({required this.lang});
  final String lang;
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr(lang, 'step_lead'),
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.5)),
        const SizedBox(height: 14),
        _StepItem(
          num: '1',
          numColor: AppColors.navy,
          title: tr(lang, 'step1_t'),
          desc: tr(lang, 'step1_d'),
          btnLabel: tr(lang, 'step1_btn'),
          btnBg: AppColors.limeSoft,
          btnFg: AppColors.navyDeep,
          onTap: () => showReminderSheet(context),
        ),
        const SizedBox(height: 12),
        _StepItem(
          num: '2',
          numColor: AppColors.red,
          title: tr(lang, 'step2_t'),
          desc: tr(lang, 'step2_d'),
          btnLabel: tr(lang, 'step2_btn'),
          btnBg: AppColors.redSoft,
          btnFg: AppColors.red,
          onTap: () => showComplaintSheet(context),
        ),
      ]),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.num,
    required this.numColor,
    required this.title,
    required this.desc,
    required this.btnLabel,
    required this.btnBg,
    required this.btnFg,
    required this.onTap,
  });
  final String num;
  final Color numColor;
  final String title, desc, btnLabel;
  final Color btnBg, btnFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: numColor, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(num,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(desc,
              style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(color: btnBg, borderRadius: BorderRadius.circular(10)),
              child: Text(btnLabel,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: btnFg)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ---------- 무료 3건 이후 잠금 카드 ----------
class _WorkLock extends StatelessWidget {
  const _WorkLock({required this.lang});
  final String lang;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPaywall(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.seaSoft,
          border: Border.all(color: AppColors.sea, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          const Text('🔒', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 5),
          Text(tr(lang, 'wp_lock_t'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tr(lang, 'wp_lock_s'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration:
                BoxDecoration(color: AppColors.sea, borderRadius: BorderRadius.circular(20)),
            child: Text(tr(lang, 'pl_btn'),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

/// "시급 10,320원" 같은 급여 문자열을 현재 언어의 단위·통화로 다시 조합한다.
/// (회사 상호는 고유명사라 그대로 두고, 급여 단위/통화만 로케일 대응)
String _localizedPay(String lang, String pay) {
  final kind = pay.startsWith('시급')
      ? 'wp_hourly'
      : pay.startsWith('월급')
          ? 'wp_monthly'
          : 'wp_yearly';
  final isMan = pay.contains('만'); // "2,880만원" 형태
  var won = int.tryParse(pay.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  if (isMan) won *= 10000;
  final grouped =
      won.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  final money = lang == 'ko' ? '$grouped원' : '₩$grouped';
  return '${tr(lang, kind)} $money';
}
