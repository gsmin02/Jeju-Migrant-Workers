import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';
import '../widgets/complaint_sheet.dart';
import '../widgets/time_picker_sheet.dart';

/// GPS 카드의 감귤 체크 배지 (jeju_pay svgs.dart 이식).
const String _kGpsCitrusSvg = '''
<svg viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="40" cy="44" rx="26" ry="23" fill="#f5a623" stroke="#d98324" stroke-width="2.5"/>
  <ellipse cx="30" cy="36" rx="9" ry="6" fill="#ffc562" opacity=".6"/>
  <path d="M40 21 Q46 10 56 13 Q47 19 43 27 Z" fill="#3f9750" stroke="#2f6e3a" stroke-width="1.5"/>
  <circle cx="40" cy="22" r="3" fill="#7a4f1e"/>
  <path d="M31 46 l6 6 l12 -13" fill="none" stroke="#fff" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
          _summary('${app.workDays}${tr(app.lang, 'unit_day')}', tr(app.lang, 'ws_week')),
          const SizedBox(width: 8),
          _summary('${app.totalHours.toStringAsFixed(1)}h', tr(app.lang, 'ws_hours')),
          const SizedBox(width: 8),
          _summary('${app.attendStreak}${tr(app.lang, 'unit_day')}', tr(app.lang, 'ws_streak')),
        ]),
        const SizedBox(height: 14),
        // GPS 카드
        _gpsCard(app),
        // 출퇴근 알림
        _notiCard(context, app),
        // 증거함
        _eviCard(app),
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

  // ---------- GPS 출퇴근 카드 (3상태 + SVG 링 + 실시간 로컬 날짜) ----------
  Widget _gpsCard(AppState app) {
    final lang = app.lang;
    final out = app.punchedOutDone && !app.punchedIn;
    final titleKey = app.punchedIn ? 'gps_working' : out ? 'gps_done' : 'gps_arrived';
    final subKey = app.punchedIn ? 'gps_in_done' : out ? 'gps_saved' : 'gps_near';
    final accent = out ? AppColors.amber : AppColors.sea;
    final accentDeep = out ? AppColors.amber : AppColors.seaDeep;
    final softBg = out ? AppColors.amberSoft : AppColors.seaSoft;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFFFFAF0), softBg]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3E3C4), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: .35), width: 2),
              ),
              alignment: Alignment.center,
              child: SvgPicture.string(_kGpsCitrusSvg, width: 50, height: 50),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📍 ${tr(lang, titleKey)}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accentDeep)),
                  const SizedBox(height: 3),
                  Text(tr(lang, subKey),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Text(_clock,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -.5)),
        Text(_dateLine(lang),
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
        );
  }

  String _dateLine(String lang) {
    final n = DateTime.now();
    // weekdays는 일요일부터 → DateTime.weekday(월1..일7)를 %7로 매핑.
    final wd = tr(lang, 'weekdays').split(',')[n.weekday % 7];
    return lang == 'ko'
        ? '${n.year}년 ${n.month}월 ${n.day}일 $wd요일'
        : '$wd, ${n.month}/${n.day}/${n.year}';
  }

  // ---------- 증거함 카드 ----------
  Widget _eviCard(AppState app) {
    return AppCard(
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
    );
  }

  // ---------- 출퇴근 알림 카드 ----------
  Widget _notiCard(BuildContext context, AppState app) {
    final lang = app.lang;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr(lang, 'noti_head'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(tr(lang, 'noti_desc'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.6)),
        const SizedBox(height: 8),
        _notiRow(
            child: Text(tr(lang, 'noti_auto'), style: const TextStyle(fontSize: 13)),
            on: app.notiAuto,
            onToggle: () => app.toggleNoti('auto')),
        _notiRow(
            child: Row(children: [
              Text(tr(lang, 'noti_in'), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              _timeBtn(_fmtTime(lang, app.notiInTime), () => showTimePickerSheet(context, 'in')),
            ]),
            on: app.notiIn,
            onToggle: () => app.toggleNoti('in')),
        _notiRow(
            child: Row(children: [
              Text(tr(lang, 'noti_out'), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              _timeBtn(_fmtTime(lang, app.notiOutTime), () => showTimePickerSheet(context, 'out')),
            ]),
            on: app.notiOut,
            onToggle: () => app.toggleNoti('out')),
        const SizedBox(height: 12),
        Text(tr(lang, 'noti_hint'),
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
        const SizedBox(height: 14),
        Material(
          color: AppColors.yellow,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => app.showSysNoti(tr(lang, 'noti_pv_title'), tr(lang, 'noti_pv_body')),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Text(tr(lang, 'noti_test'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF5A4A2A))),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  String _fmtTime(String lang, TimeOfDay t) {
    final mm = t.minute.toString().padLeft(2, '0');
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final ap = t.hour < 12 ? tr(lang, 'am') : tr(lang, 'pm');
    return lang == 'ko' ? '$ap $h12:$mm' : '$h12:$mm $ap';
  }

  Widget _notiRow({required Widget child, required bool on, required VoidCallback onToggle}) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(children: [
          Expanded(child: child),
          Transform.scale(
            scale: .8,
            child: Switch(
              value: on,
              activeThumbColor: AppColors.sea,
              onChanged: (_) => onToggle(),
            ),
          ),
        ]),
      );

  Widget _timeBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.seaDeep)),
        ),
      );

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
