import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import 'common.dart';

/// 🔔 출퇴근 알림 시간 선택 시트. [which]는 'in' 또는 'out'.
void showTimePickerSheet(BuildContext context, String which) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _TimePickerSheet(which: which),
  );
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.which});
  final String which;
  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late bool isPm;
  late int hour12;
  late int minute;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final t = widget.which == 'in' ? app.notiInTime : app.notiOutTime;
    isPm = t.hour >= 12;
    hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    minute = t.minute;
  }

  String _preview(String lang) {
    final mm = minute.toString().padLeft(2, '0');
    final ap = isPm ? tr(lang, 'pm') : tr(lang, 'am');
    return lang == 'ko' ? '$ap $hour12:$mm' : '$hour12:$mm $ap';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().lang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
              child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 14),
          Text(tr(lang, widget.which == 'in' ? 'tp_title_in' : 'tp_title_out'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tr(lang, 'tp_sub'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 16),
            child: Text(
              _preview(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.seaDeep,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Row(children: [
            Expanded(child: _apButton(tr(lang, 'am'), !isPm, () => setState(() => isPm = false))),
            const SizedBox(width: 8),
            Expanded(child: _apButton(tr(lang, 'pm'), isPm, () => setState(() => isPm = true))),
          ]),
          const SizedBox(height: 18),
          _label(tr(lang, 'tp_hour')),
          const SizedBox(height: 9),
          _cellGrid(
            values: [for (var h = 1; h <= 12; h++) h],
            labels: [for (var h = 1; h <= 12; h++) '$h'],
            isOn: (v) => v == hour12,
            onPick: (v) => setState(() => hour12 = v),
          ),
          const SizedBox(height: 18),
          _label(tr(lang, 'tp_min')),
          const SizedBox(height: 9),
          _cellGrid(
            values: const [0, 10, 20, 30, 40, 50],
            labels: const ['00', '10', '20', '30', '40', '50'],
            isOn: (v) => v == minute,
            onPick: (v) => setState(() => minute = v),
          ),
          const SizedBox(height: 18),
          BigButton(tr(lang, 'tp_set'), () {
            var h24 = hour12 % 12;
            if (isPm) h24 += 12;
            context.read<AppState>().setNotiTime(widget.which, TimeOfDay(hour: h24, minute: minute));
            Navigator.of(context).pop();
            toast(context, tr(lang, 'tp_set_toast').replaceAll('{t}', _preview(lang)));
          }),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft));

  Widget _apButton(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? AppColors.sea : Colors.white,
            border: Border.all(color: on ? AppColors.sea : AppColors.line, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : AppColors.inkSoft)),
        ),
      );

  Widget _cellGrid({
    required List<int> values,
    required List<String> labels,
    required bool Function(int) isOn,
    required void Function(int) onPick,
  }) =>
      GridView.count(
        crossAxisCount: 6,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 1.25,
        children: [
          for (var i = 0; i < values.length; i++)
            GestureDetector(
              onTap: () => onPick(values[i]),
              child: Container(
                decoration: BoxDecoration(
                  color: isOn(values[i]) ? AppColors.seaSoft : Colors.white,
                  border: Border.all(
                      color: isOn(values[i]) ? AppColors.sea : AppColors.line, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: isOn(values[i]) ? FontWeight.w800 : FontWeight.w700,
                        color: isOn(values[i]) ? AppColors.seaDeep : AppColors.ink)),
              ),
            ),
        ],
      );
}
