import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  bool hot = true;

  void _gate(BuildContext context, VoidCallback ok) {
    final app = context.read<AppState>();
    if (app.masked) {
      showPaywall(context);
    } else {
      ok();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
      children: [
        ViewHeader(tr(app.lang, 'comm_title'), tr(app.lang, 'comm_sub')),
        if (!app.previewPaid) _freeBadge('🎉 오픈 기간 — 글쓰기·읽기 모두 무료예요'),
        // 질문하기 박스
        GestureDetector(
          onTap: () => _gate(context, () => _openWrite(context)),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line), boxShadow: kCardShadow),
            child: Row(children: [
              Container(width: 36, height: 36,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.sea, AppColors.seaDeep]),
                      shape: BoxShape.circle),
                  alignment: Alignment.center, child: const Text('✨', style: TextStyle(fontSize: 16))),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('궁금한 점을 물어보세요 · 글 작성 시 +50P',
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _sortTab('🔥 인기순', hot, () => setState(() => hot = true)),
          const SizedBox(width: 8),
          _sortTab('🕐 최신순', !hot, () => setState(() => hot = false)),
        ]),
        const SizedBox(height: 12),
        // 핀 고정
        const Text('📌 오늘의 핫한 주제',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
        const SizedBox(height: 8),
        _postCard(context,
            cat: '임금체불', meta: '🔥 조회 214 · 답변 6',
            title: '사장이 "다음 달에 준다"만 반복해요',
            body: '2달째 월급을 안 주는데 계속 미뤄요. 지금 뭘 해야 하나요?',
            answer: '지금 바로 SOS 탭에서 1350 상담을 받으세요. GPS 근무기록을 캡처해두면 진정 접수 시 증거가 됩니다.',
            hot: true),
        const SectionLabel('인기 글'),
        _postCard(context,
            cat: '계약', meta: '👀 388 · 💬 9 · 어제',
            title: '근로계약서를 안 써줬어요',
            body: '일 시작한 지 한 달인데 계약서가 없어요. 이래도 되나요?',
            comment: '익명 · 네팔  저도 계약서 없었는데 GPS 기록으로 해결했어요.'),
        _postCard(context,
            cat: '임금체불', meta: '👀 214 · 💬 6 · 3시간 전',
            title: '양식장 3개월치 밀렸다가 받은 후기',
            body: 'GPS 기록 제출했더니 사장이 인정했어요. 다들 꼭 매일 찍으세요! 🙏',
            comment: '익명 · 인도네시아  축하해요! 저도 매일 찍고 있어요 🙏'),
        _postCard(context,
            cat: '제주생활', meta: '👀 96 · 💬 4 · 2일 전',
            title: '성산에서 병원 갈 때 통역 되는 곳?',
            body: '아파서 병원 가야 하는데 한국어가 서툴러요.',
            comment: '익명 · 베트남  외국인노동자지원센터(064-712-1141)에 전화하면 통역 도와줘요.'),
      ],
    );
  }

  Widget _freeBadge(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.limeSoft, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.limeDeep)),
        child: Text(text,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4A5D2A))),
      );

  Widget _sortTab(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.sea : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? AppColors.sea : AppColors.line),
          ),
          child: Text(label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: on ? Colors.white : AppColors.inkSoft)),
        ),
      );

  Widget _postCard(BuildContext context,
      {required String cat, required String meta, required String title, required String body,
      String? answer, String? comment, bool hot = false}) {
    return GestureDetector(
      onTap: () => _gate(context, () => _openPost(context, title, body)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: hot ? null : AppColors.card,
          gradient: hot ? const LinearGradient(colors: [Color(0xFFFFFDF5), AppColors.seaSoft]) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hot ? AppColors.sea : AppColors.line, width: hot ? 1.5 : 1),
          boxShadow: kCardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Pill(cat, bg: AppColors.seaSoft, fg: AppColors.seaDeep),
            const Spacer(),
            Text(meta, style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
          ]),
          const SizedBox(height: 7),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.4)),
          if (answer != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('✨ AI 도우미 + 선배 노동자',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                const SizedBox(height: 3),
                Text(answer, style: const TextStyle(fontSize: 12, height: 1.4)),
              ]),
            ),
          ],
          if (comment != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF6EA),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text('💬 $comment',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF55503F), height: 1.4)),
            ),
          ],
        ]),
      ),
    );
  }

  void _openWrite(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 5,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 14),
          const Text('✍️ 글 쓰기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(hintText: '제목을 입력하세요', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          const TextField(maxLines: 4, decoration: InputDecoration(hintText: '내용을 자유롭게 적어주세요', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          BigButton('올리기 (+50P)', () {
            context.read<AppState>().points; // no-op read
            Navigator.pop(context);
            toast(context, '글이 등록됐어요 · +50P (데모)');
          }),
        ]),
      ),
    );
  }

  void _openPost(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: .8, maxChildSize: .92,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 5,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
            const SizedBox(height: 6),
            const Text('🧑 익명 · 네팔', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 14, height: 1.65)),
            const Divider(height: 28),
            const Text('댓글 3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _cmt('✨ AI 도우미', '축하해요! 아직 못 받은 분들은 SOS 탭의 1350 상담과 대지급금 제도를 확인하세요.', true),
            _cmt('🧑 익명 · 인도네시아', '저도 2달 밀렸어요. GPS 기록 매일 찍고 있어요. 힘이 되네요.', false),
            _cmt('🧑 익명 · 베트남', '어느 지원센터 통해서 받으셨어요? 저도 상담받고 싶어요.', false),
          ]),
        ),
      ),
    );
  }

  Widget _cmt(String who, String text, bool ai) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: ai ? AppColors.seaSoft : const Color(0xFFFAF7EF),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(who, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ]),
      );
}
