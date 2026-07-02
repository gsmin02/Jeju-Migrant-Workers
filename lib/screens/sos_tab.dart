import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SosTab extends StatefulWidget {
  const SosTab({super.key});
  @override
  State<SosTab> createState() => _SosTabState();
}

class _SosTabState extends State<SosTab> {
  final _open = <int>{};

  static const _situations = [
    ['월급이 밀렸어요',
      '먼저 이 앱의 근무기록을 캡처해 증거로 보관하세요. 그다음 고용노동부 1350에 전화하거나 노동포털(labor.moel.go.kr)에서 임금체불 진정을 넣습니다. 퇴직 후 14일이 지나도 안 주면 명백한 위반입니다.'],
    ['사업주가 신고하면 쫓겨난다고 협박해요',
      '임금체불 진정을 이유로 한 해고·불이익은 불법입니다. 협박 내용을 녹음·메모해 함께 제보하세요. 제주 지원센터가 비밀 상담과 통역을 지원합니다.'],
    ['미등록(비자 만료) 상태인데 신고해도 되나요?',
      '체류 자격과 상관없이 일한 임금은 받을 권리가 있습니다. 2025년 11월부터는 노동청 조사 중 알게 된 미등록 체류를 출입국에 통보하지 않도록 법령에 명시됐습니다(출입국관리법 시행규칙 제70조의2). 다만 신고 전 지원센터의 비밀 상담을 먼저 받는 것이 안전합니다.'],
    ['일하다 다쳤어요',
      '일하다 다치면 산업재해보상보험으로 치료비와 휴업급여를 받을 수 있습니다. 미등록 노동자도 신청 가능합니다. 근로복지공단(1588-0075) 또는 제주 지원센터에 문의하세요.'],
  ];

  static const _programs = [
    ['임금체불 진정 (고용노동부)', '노동청에 진정하면 근로감독관이 조사해 사업주에게 지급을 지시합니다.', '무료 · 다국어 상담'],
    ['간이대지급금 제도', '사업주가 못 주거나 도산한 경우, 국가가 최대 1,000만원까지 먼저 지급합니다(임금채권보장법 제7조의2).', '최대 1,000만원'],
    ['무료 법률구조 (대한법률구조공단)', '체불 소송이 필요할 때 무료로 변호사 조력을 받을 수 있습니다. 외국인도 신청 가능.', '소송 지원'],
    ['제주외국인노동자지원센터', '상담·통역·한국어교육·의료공제까지. 제주 현지 거점입니다.', '제주 현지 · 통역'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        // 히어로
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.red, Color(0xFF8E2B20)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🆘 임금체불, 혼자 겪지 마세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('제주에는 도와줄 곳이 있습니다. 아래는 무료로 상담·신고할 수 있는 공식 창구예요.',
                style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
            const SizedBox(height: 12),
            Row(children: [
              _sosBtn(context, '📞 1350', '고용노동부'),
              const SizedBox(width: 8),
              _sosBtn(context, '📞 064-712-1141', '제주 지원센터'),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        const SectionLabel('이럴 땐 어떻게? — 상황별 안내'),
        ...List.generate(_situations.length, (i) {
          final open = _open.contains(i);
          return GestureDetector(
            onTap: () => setState(() => open ? _open.remove(i) : _open.add(i)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.line), boxShadow: kCardShadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(_situations[i][0],
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ),
                  Text(open ? '▲' : '▾', style: const TextStyle(color: AppColors.inkSoft)),
                ]),
                if (open) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.line),
                  ),
                  Text(_situations[i][1],
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.5)),
                ],
              ]),
            ),
          );
        }),
        const SectionLabel('임금체불 관련 정부 지원제도'),
        ..._programs.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(11),
                border: const Border(left: BorderSide(color: AppColors.sea, width: 4)),
                boxShadow: kCardShadow,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p[0], style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(p[1], style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4)),
                const SizedBox(height: 7),
                Pill(p[2], bg: AppColors.seaSoft, fg: AppColors.seaDeep),
              ]),
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(10)),
          child: const Text(
              '표시된 제도·연락처는 이해를 돕기 위한 예시이며, 실제 신청 전 고용노동부·제주 지원센터에서 최신 내용을 확인하세요. 이 앱은 법률 자문을 제공하지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.inkSoft, height: 1.5)),
        ),
      ],
    );
  }

  Widget _sosBtn(BuildContext context, String num, String label) => Expanded(
        child: GestureDetector(
          onTap: () => toast(context, '$label 연결 (데모)'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white30),
            ),
            child: Column(children: [
              Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ]),
          ),
        ),
      );
}
