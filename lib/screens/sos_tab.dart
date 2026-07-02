import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';

class SosTab extends StatefulWidget {
  const SosTab({super.key});
  @override
  State<SosTab> createState() => _SosTabState();
}

class _SosTabState extends State<SosTab> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().lang;
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
            Text(tr(lang, 'sos_h'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 4),
            Text(tr(lang, 'sos_p'),
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
            const SizedBox(height: 12),
            Row(children: [
              _sosBtn(context, lang, '📞 1350', tr(lang, 'sos_moel')),
              const SizedBox(width: 8),
              _sosBtn(context, lang, '📞 064-712-1141', tr(lang, 'sos_center')),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        SectionLabel(tr(lang, 'sos_sit_sec')),
        ...List.generate(4, (i) {
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
                    child: Text(tr(lang, 'sos_q${i + 1}'),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                  ),
                  Text(open ? '▲' : '▼',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ]),
                if (open) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.line),
                  ),
                  Text(tr(lang, 'sos_a${i + 1}'),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.5)),
                ],
              ]),
            ),
          );
        }),
        SectionLabel(tr(lang, 'sos_prog_sec')),
        ...List.generate(4, (idx) {
          final i = idx + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(11),
              border: const Border(left: BorderSide(color: AppColors.sea, width: 4)),
              boxShadow: kCardShadow,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(lang, 'prog${i}_n'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(tr(lang, 'prog${i}_d'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4)),
              const SizedBox(height: 7),
              Pill(tr(lang, 'prog${i}_t'), bg: AppColors.seaSoft, fg: AppColors.seaDeep),
            ]),
          );
        }),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(10)),
          child: Text(
              tr(lang, 'sos_disc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppColors.inkSoft, height: 1.5)),
        ),
      ],
    );
  }

  Widget _sosBtn(BuildContext context, String lang, String num, String label) => Expanded(
        child: GestureDetector(
          onTap: () => toast(context, tr(lang, 'sos_call_toast').replaceAll('{label}', label)),
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
