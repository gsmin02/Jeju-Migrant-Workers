import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';
import '../widgets/complaint_sheet.dart';

class RecordTab extends StatefulWidget {
  const RecordTab({super.key});
  @override
  State<RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<RecordTab> {
  Timer? _timer;
  String _clock = '--:--';

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final n = DateTime.now();
    final s = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    if (s != _clock && mounted) setState(() => _clock = s);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        ViewHeader(tr(app.lang, 'record_title'), tr(app.lang, 'record_sub')),
        // 주간 요약
        Row(children: [
          _summary('5${tr(app.lang, 'unit_day')}', tr(app.lang, 'ws_week')),
          const SizedBox(width: 8),
          _summary('47.2h', tr(app.lang, 'ws_hours')),
          const SizedBox(width: 8),
          _summary('4${tr(app.lang, 'unit_day')}', tr(app.lang, 'ws_streak')),
        ]),
        const SizedBox(height: 14),
        // GPS 카드
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: app.punchedIn
                        ? [const Color(0xFFFFFAF0), AppColors.seaSoft]
                        : [const Color(0xFFFFFAF0), AppColors.amberSoft]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3E3C4), width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 60, height: 60,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Text('🍊', style: TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.punchedIn ? tr(app.lang, 'gps_working') : tr(app.lang, 'gps_arrived'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                      const SizedBox(height: 3),
                      Text(app.punchedIn ? tr(app.lang, 'gps_in_done') : tr(app.lang, 'gps_near'),
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text(_clock,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            Text(tr(app.lang, 'rec_date'),
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _punchBtn(tr(app.lang, 'punch_in'), const [Color(0xFFF9B84E), Color(0xFFF5A623)],
                    enabled: !app.punchedIn, onTap: () {
                  app.punch(true, _clock);
                  toast(context, tr(app.lang, 'toast_punch_in').replaceAll('{t}', _clock));
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _punchBtn(tr(app.lang, 'punch_out'), const [Color(0xFF4E9A5A), Color(0xFF3F7D4F)],
                    enabled: app.punchedIn, onTap: () {
                  app.punch(false, _clock);
                  toast(context, tr(app.lang, 'toast_punch_out'));
                }),
              ),
            ]),
          ]),
        ),
        // 증거함
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(app.lang, 'evi_head'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _evi(AppColors.sea, tr(app.lang, 'evi_gps'), null, '91${tr(app.lang, 'unit_case')}'),
            _evi(AppColors.limeDeep, tr(app.lang, 'evi_jobad'),
                app.jobAd != null
                    ? tr(app.lang, 'evi_jobad_saved').replaceAll('{name}', app.jobAd!)
                    : tr(app.lang, 'evi_jobad_none'),
                app.jobAd != null ? '✓' : '—'),
            _evi(AppColors.amber, tr(app.lang, 'evi_coworker'), tr(app.lang, 'evi_coworker_d'), '✓'),
          ]),
        ),
        // 최근 기록
        SectionLabel(tr(app.lang, 'rec_recent')),
        AppCard(
          child: Column(
            children: app.logs
                .map((l) => _logItem(l.date, l.detail, l.hours, l.source))
                .toList(),
          ),
        ),
        const SizedBox(height: 6),
        BigButton(
          '📄 ${tr(app.lang, 'complaint_btn')}',
          () => showComplaintSheet(context),
          sub: tr(app.lang, 'complaint_btn_sub'),
          color: AppColors.navy,
        ),
      ],
    );
  }

  Widget _summary(String n, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.line), boxShadow: kCardShadow,
          ),
          child: Column(children: [
            Text(n, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
            const SizedBox(height: 2),
            Text(l, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
          ]),
        ),
      );

  Widget _punchBtn(String label, List<Color> colors,
          {required bool enabled, required VoidCallback onTap}) =>
      Opacity(
        opacity: enabled ? 1 : .35,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  Widget _evi(Color dot, String title, String? detail, String right) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              if (detail != null)
                Text(detail, style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
            ]),
          ),
          Text(right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
        ]),
      );

  Widget _logItem(String date, String detail, String hrs, String src) {
    final srcColor = src == '직접입력' ? AppColors.amber : AppColors.seaDeep;
    final srcBg = src == '직접입력' ? AppColors.amberSoft : AppColors.seaSoft;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Container(width: 9, height: 9,
            decoration: const BoxDecoration(color: AppColors.sea, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            Text(detail, style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(hrs, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: srcBg, borderRadius: BorderRadius.circular(6)),
            child: Text(src, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: srcColor)),
          ),
        ]),
      ]),
    );
  }
}
