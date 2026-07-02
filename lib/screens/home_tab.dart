import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';
import '../widgets/shop_sheet.dart';

class HomeTab extends StatelessWidget {
  final ValueChanged<int> onGoTab;
  const HomeTab({super.key, required this.onGoTab});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        _ProfileHero(app: app),
        SectionLabel(tr(app.lang, 'h_data_label')),
        const _WageChartCard(),
        const _NationalityCard(),
        SectionLabel(tr(app.lang, 'h_know_label')),
        _KnowCard('📅', AppColors.seaSoft, tr(app.lang, 'k1_t'), tr(app.lang, 'k1_d'),
            () => onGoTab(4)),
        _KnowCard('📸', AppColors.limeSoft, tr(app.lang, 'k2_t'), tr(app.lang, 'k2_d'),
            () => onGoTab(1)),
        _KnowCard('🛡️', AppColors.redSoft, tr(app.lang, 'k3_t'), tr(app.lang, 'k3_d'),
            () => onGoTab(4)),
        _KnowCard('💰', AppColors.yellow, tr(app.lang, 'k4_t'), tr(app.lang, 'k4_d'),
            () => onGoTab(4)),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final AppState app;
  const _ProfileHero({required this.app});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2E9B8), width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 아바타
              GestureDetector(
                onTap: () => showShopSheet(context),
                child: Container(
                  width: 110, height: 168,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Colors.white, Color(0xFFFDF3E0)]),
                    border: Border.all(color: AppColors.ink, width: 2.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🧑‍🌾', style: TextStyle(fontSize: 54))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _pill(tr(app.lang, 'p_name'), 'Bibek'),
                    const SizedBox(height: 8),
                    _pill(tr(app.lang, 'p_site'), '한라양식'),
                    const SizedBox(height: 8),
                    _pill(tr(app.lang, 'p_tenure'), '1년 2개월'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => showShopSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.white, AppColors.seaSoft]),
                          border: Border.all(color: const Color(0xFFF0D9B0), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text('${app.points}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                          const Text(' P',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sea)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AttendCard(app: app),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(color: AppColors.lime, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.limeDeep)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4A5D2A))),
        ]),
      );
}

class _AttendCard extends StatelessWidget {
  final AppState app;
  const _AttendCard({required this.app});
  @override
  Widget build(BuildContext context) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final doneCount = app.attended ? 3 : 2; // 월화(+오늘)
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🍊 매일 출석 체크',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('출석할 때마다 +5P · 연속 ${app.attendStreak}일째',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: app.attended
                ? null
                : () {
                    app.checkAttend();
                    toast(context, '🍊 출석 완료! +5P 적립 (총 ${app.points}P)');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sea,
              disabledBackgroundColor: const Color(0xFFCFE3D2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            child: Text(app.attended ? '출석 완료 ✓' : '출석 +5P',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (i) {
            final done = i < doneCount;
            final today = i == 2;
            return Expanded(
              child: Column(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: done ? AppColors.seaSoft : const Color(0xFFF5F0E2),
                    shape: BoxShape.circle,
                    border: (done || today)
                        ? Border.all(color: AppColors.sea, width: 1.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(done ? '🍊' : '·',
                      style: TextStyle(fontSize: done ? 15 : 15, color: const Color(0xFFC9BDA0))),
                ),
                const SizedBox(height: 3),
                Text(days[i], style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
              ]),
            );
          }),
        ),
      ]),
    );
  }
}

class _WageChartCard extends StatelessWidget {
  const _WageChartCard();
  // 연도, 금액(억), 추정여부
  static const _bars = [
    ['2020', 46.0, '162억', false],
    ['2021', 51.0, '180억', true],
    ['2022', 57.0, '200억', true],
    ['2023', 63.0, '219억', false],
    ['2024', 83.0, '290억', false],
    ['2025', 78.0, '272억', false],
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _bars.map((b) {
                final pct = (b[1] as double) / 100;
                final est = b[3] as bool;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(b[2] as String,
                            style: TextStyle(
                                fontSize: 9.5, fontWeight: FontWeight.w800,
                                color: est ? const Color(0xFFA89878) : AppColors.ink)),
                        const SizedBox(height: 2),
                        Container(
                          height: 120 * pct,
                          decoration: BoxDecoration(
                            gradient: est
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                    colors: (b[0] as String).compareTo('2023') >= 0
                                        ? [const Color(0xFF6A86D4), const Color(0xFF4A6BC9)]
                                        : [const Color(0xFFEFB44E), const Color(0xFFE5A333)]),
                            color: est ? const Color(0xFFE8E0D0) : null,
                            border: est
                                ? Border.all(color: const Color(0xFFC9BDA0), width: 1.5)
                                : null,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(b[0] as String,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Text('출처: 제주근로개선지도센터·제주도 (2021·2022년은 추정치)',
              style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _NationalityCard extends StatelessWidget {
  const _NationalityCard();
  static const _nats = [
    ['🇳🇵', '네팔', 1.0, '903', '+82%', false],
    ['🇮🇩', '인도네시아', .97, '873', '+158%', true],
    ['🇱🇰', '스리랑카', .53, '474', '+25%', false],
    ['🇰🇭', '캄보디아', .37, '335', '+55%', false],
    ['🇻🇳', '베트남', .23, '206', '+33%', false],
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return AppCard(
      color: AppColors.seaSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(app.lang, 'h_jeju_head'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._nats.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Text(n[0] as String, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 62,
                    child: Text(n[1] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: n[2] as double, minHeight: 12,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation(AppColors.sea),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(n[3] as String, textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(n[4] as String, textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                            color: (n[5] as bool) ? AppColors.red : AppColors.green)),
                  ),
                ]),
              )),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
            child: const Text(
                '💡 제주 E-9 노동자는 3년 만에 2,027명 → 3,519명(+73%)으로 늘었어요. 우리는 결코 소수가 아닙니다.',
                style: TextStyle(fontSize: 12, color: Color(0xFF5A4A2A), height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _KnowCard extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title, desc;
  final VoidCallback onTap;
  const _KnowCard(this.icon, this.iconBg, this.title, this.desc, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
            boxShadow: kCardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.35)),
                    const SizedBox(height: 3),
                    Text(desc,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
