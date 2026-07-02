import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import 'common.dart';

/// 👥 친구 초대 시트 — 내 초대 코드 공유 + 받은 코드 입력(적용).
void showInviteSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _InviteSheet(),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();
  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem(String lang) async {
    final code = _code.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() => _busy = true);
    final result = await context.read<AppState>().redeemInvite(code);
    if (!mounted) return;
    setState(() => _busy = false);
    const okKeys = {'ok', 'already', 'notfound', 'self'};
    final key = okKeys.contains(result) ? 'iv_$result' : 'iv_err';
    toast(context, tr(lang, key));
    if (result == 'ok') Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
    final code = app.inviteCode ?? '—';
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 14),
          Text(tr(lang, 'iv_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tr(lang, 'iv_sub'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.45)),
          const SizedBox(height: 16),
          // 내 초대 코드 + 복사
          Text(tr(lang, 'iv_my_code'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.seaSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sea, width: 1.5),
            ),
            child: Row(children: [
              Expanded(
                child: Text(code,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: AppColors.seaDeep)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  toast(context, tr(lang, 'iv_copied'));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration:
                      BoxDecoration(color: AppColors.sea, borderRadius: BorderRadius.circular(10)),
                  child: Text('📋 ${tr(lang, 'iv_copy')}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // 받은 코드 입력
          Text(tr(lang, 'iv_enter_label'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: tr(lang, 'iv_enter_hint'),
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
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.limeDeep,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _busy ? null : () => _redeem(lang),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  child: _busy
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(tr(lang, 'iv_redeem'),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
            child: Text(tr(lang, 'iv_note'),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF5A4A2A), height: 1.5)),
          ),
        ],
      ),
    );
  }
}
