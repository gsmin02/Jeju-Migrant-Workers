import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../services/complaint_service.dart';
import 'common.dart';

void showComplaintSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ComplaintSheet(),
  );
}

class _ComplaintSheet extends StatefulWidget {
  const _ComplaintSheet();
  @override
  State<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends State<_ComplaintSheet> {
  final _wage = TextEditingController(text: '월 220만원');
  final _period = TextEditingController(text: '2026년 5월 ~ 6월');
  bool _loading = false;
  bool _showKo = true;
  ComplaintResult? _result;

  @override
  void dispose() {
    _wage.dispose();
    _period.dispose();
    super.dispose();
  }

  List<Map<String, String>> _logs(AppState app) => app.logs.map((l) {
        final parts = l.detail.split('–');
        final inT = parts.isNotEmpty ? parts[0].trim() : '';
        final outT = parts.length > 1 ? parts[1].split('·')[0].trim() : '';
        return {'date': l.date, 'in': inT, 'out': outT, 'src': l.source};
      }).toList();

  Future<void> _generate() async {
    final app = context.read<AppState>();
    setState(() => _loading = true);
    final r = await complaintService.generate(
      name: 'Bibek',
      nationality: '네팔',
      lang: app.lang == 'ko' ? 'en' : app.lang,
      promisedWage: _wage.text,
      unpaidPeriod: _period.text,
      logs: _logs(app),
    );
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
    toast(context, r.fallback ? '📄 진정서 초안 (샘플)' : '✅ 진정서 초안이 생성됐어요');
  }

  Future<void> _pdf() async {
    final text = _result?.complaintKo ?? '';
    try {
      final font = await PdfGoogleFonts.nanumGothicRegular();
      final bold = await PdfGoogleFonts.nanumGothicBold();
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        build: (_) => [
          pw.Text(text, style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
        ],
      ));
      await Printing.layoutPdf(onLayout: (f) => doc.save(), name: '임금체불_진정서.pdf');
    } catch (e) {
      if (mounted) toast(context, 'PDF 생성 실패: 인터넷 연결을 확인해 주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      maxChildSize: .94,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42, height: 5,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 14),
            const Text('📄 임금체불 진정서 만들기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('쌓인 GPS 기록에 두 가지만 더하면, 노동청 제출용 초안이 만들어져요.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            if (_result == null) ...[
              _label('약속받은 임금'),
              _input(_wage),
              const SizedBox(height: 10),
              _label('못 받은 기간'),
              _input(_period),
              const SizedBox(height: 16),
              _loading
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: const Column(children: [
                        CircularProgressIndicator(color: AppColors.sea),
                        SizedBox(height: 10),
                        Text('생성 중… (기록 분석)', style: TextStyle(color: AppColors.inkSoft)),
                      ]),
                    )
                  : BigButton('진정서 초안 생성', _generate),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(11)),
                child: const Text(
                    '💡 함께 첨부됨: GPS 출퇴근 기록 91건 · 채용공고 · 동료 교차기록(같은 사업장 6명)',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF5A4A2A), height: 1.5)),
              ),
            ] else ...[
              Row(children: [
                _tab('🇰🇷 진정서 (한국어)', _showKo, () => setState(() => _showKo = true)),
                const SizedBox(width: 8),
                _tab('🌐 내 언어 요약', !_showKo, () => setState(() => _showKo = false)),
              ]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _showKo ? Colors.white : AppColors.seaSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(_showKo ? _result!.complaintKo : _result!.summaryNative,
                    style: TextStyle(fontSize: _showKo ? 12.5 : 13, height: 1.55)),
              ),
              const SizedBox(height: 12),
              BigButton('🖨 PDF로 저장', _pdf),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                    '참고용 초안입니다. 제출 전 1350 또는 지원센터(064-712-1141)에서 확인하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.inkSoft, height: 1.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
      );

  Widget _input(TextEditingController c) => TextField(
        controller: c,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: true, fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.sea, width: 1.5)),
        ),
      );

  Widget _tab(String label, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.sea : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: on ? AppColors.sea : AppColors.line),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                    color: on ? Colors.white : AppColors.inkSoft)),
          ),
        ),
      );
}
