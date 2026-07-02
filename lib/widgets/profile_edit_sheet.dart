import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import 'common.dart';

/// ✏️ 프로필 편집 — 이름·사업지·근속·국적을 수정해 DB에 저장.
void showProfileEditSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ProfileEditSheet(),
  );
}

const _nationalities = [
  '네팔', '베트남', '인도네시아', '캄보디아', '스리랑카', '태국',
  '미얀마', '필리핀', '방글라데시', '몽골', '우즈베키스탄', '중국', '기타',
];

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet();
  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _workplace;
  late final TextEditingController _tenure;
  String? _nationality;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.name ?? '');
    _workplace = TextEditingController(text: app.workplace ?? '');
    _tenure = TextEditingController(text: app.tenure ?? '');
    _nationality = _nationalities.contains(app.nationality) ? app.nationality : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _workplace.dispose();
    _tenure.dispose();
    super.dispose();
  }

  Future<void> _save(String lang) async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<AppState>().updateProfile(
          name: _name.text.trim(),
          workplace: _workplace.text.trim(),
          tenure: _tenure.text.trim(),
          nationality: _nationality,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    toast(context, tr(lang, 'pe_done'));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<AppState>().lang;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 26),
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
          Text('✏️ ${tr(lang, 'p_edit')}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _label(tr(lang, 'au_name')),
          _input(_name, hint: tr(lang, 'au_name_hint')),
          const SizedBox(height: 12),
          _label(tr(lang, 'ws_name')),
          _input(_workplace, hint: tr(lang, 'ws_name_hint')),
          const SizedBox(height: 12),
          _label(tr(lang, 'ws_tenure')),
          _input(_tenure, hint: tr(lang, 'ws_tenure_hint')),
          const SizedBox(height: 12),
          _label(tr(lang, 'au_nat')),
          DropdownButtonFormField<String>(
            initialValue: _nationality,
            isExpanded: true,
            menuMaxHeight: 320,
            icon: const Icon(Icons.expand_more, color: AppColors.inkSoft),
            hint: Text(tr(lang, 'au_nat_hint'),
                style: const TextStyle(color: Color(0xFFB0A98F), fontSize: 14)),
            decoration: _dec(),
            items: [
              for (final n in _nationalities)
                DropdownMenuItem(value: n, child: Text(n, style: const TextStyle(fontSize: 14))),
            ],
            onChanged: (v) => setState(() => _nationality = v),
          ),
          const SizedBox(height: 20),
          _busy
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(color: AppColors.sea),
                  ),
                )
              : BigButton(tr(lang, 'pe_save'), () => _save(lang)),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.sea, width: 1.5)),
      );

  Widget _input(TextEditingController c, {String? hint}) =>
      TextField(controller: c, decoration: _dec(hint: hint));
}
