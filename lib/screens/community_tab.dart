import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  bool hot = true;
  late Future<List<CommunityPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = supabase.fetchPosts(hot: hot);
  }

  void _setSort(bool h) {
    if (hot == h) return;
    setState(() {
      hot = h;
      _future = supabase.fetchPosts(hot: hot);
    });
  }

  void _reload() => setState(() => _future = supabase.fetchPosts(hot: hot));

  void _gate(BuildContext context, VoidCallback ok) {
    if (context.read<AppState>().masked) {
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
          _sortTab('🔥 인기순', hot, () => _setSort(true)),
          const SizedBox(width: 8),
          _sortTab('🕐 최신순', !hot, () => _setSort(false)),
        ]),
        const SizedBox(height: 12),
        FutureBuilder<List<CommunityPost>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppColors.sea)),
              );
            }
            final posts = snap.data ?? const <CommunityPost>[];
            if (posts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('아직 글이 없어요 · 첫 글을 남겨보세요',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              );
            }
            final pinned = posts.where((p) => p.pinned).toList();
            final rest = posts.where((p) => !p.pinned).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pinned.isNotEmpty) ...[
                const Text('📌 오늘의 핫한 주제',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                const SizedBox(height: 8),
                ...pinned.map((p) => _postCard(context, p)),
              ],
              SectionLabel(hot ? '인기 글' : '최신 글'),
              ...rest.map((p) => _postCard(context, p)),
            ]);
          },
        ),
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

  Widget _postCard(BuildContext context, CommunityPost p) {
    return GestureDetector(
      onTap: () => _gate(context, () => _openPost(context, p)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: p.pinned ? null : AppColors.card,
          gradient: p.pinned ? const LinearGradient(colors: [Color(0xFFFFFDF5), AppColors.seaSoft]) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.pinned ? AppColors.sea : AppColors.line, width: p.pinned ? 1.5 : 1),
          boxShadow: kCardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Pill(p.category.isEmpty ? '기타' : p.category, bg: AppColors.seaSoft, fg: AppColors.seaDeep),
            const Spacer(),
            Text('👍 ${p.likes}', style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
          ]),
          const SizedBox(height: 7),
          Text(p.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          if (p.body.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(p.body, style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.4)),
          ],
          if (p.aiAnswer != null && p.aiAnswer!.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('✨ AI 도우미 + 선배 노동자',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                const SizedBox(height: 3),
                Text(p.aiAnswer!, style: const TextStyle(fontSize: 12, height: 1.4)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  void _openWrite(BuildContext context) {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    String category = '임금체불';
    const cats = ['임금체불', '계약', '비자', '제주생활', '기타'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(sheetCtx).viewInsets.bottom + 26),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 5,
                decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            const Text('✍️ 글 쓰기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, children: [
              for (final c in cats)
                GestureDetector(
                  onTap: () => setSheet(() => category = c),
                  child: Pill(c,
                      bg: category == c ? AppColors.sea : AppColors.seaSoft,
                      fg: category == c ? Colors.white : AppColors.seaDeep),
                ),
            ]),
            const SizedBox(height: 10),
            TextField(controller: titleC,
                decoration: const InputDecoration(hintText: '제목을 입력하세요', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: bodyC, maxLines: 4,
                decoration: const InputDecoration(hintText: '내용을 자유롭게 적어주세요', border: OutlineInputBorder())),
            const SizedBox(height: 14),
            BigButton('올리기 (+50P)', () async {
              final title = titleC.text.trim();
              if (title.isEmpty) {
                toast(context, '제목을 입력해 주세요');
                return;
              }
              final err = await supabase.addPost(category, title, bodyC.text.trim());
              if (!sheetCtx.mounted) return;
              Navigator.pop(sheetCtx);
              if (err != null) {
                toast(context, err);
              } else {
                toast(context, '글이 등록됐어요');
                _reload();
              }
            }),
          ]),
        ),
      ),
    );
  }

  void _openPost(BuildContext context, CommunityPost p) {
    Future<List<PostComment>> commentsF = supabase.fetchComments(p.id);
    final input = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => DraggableScrollableSheet(
          expand: false, initialChildSize: .8, maxChildSize: .92,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 5,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
              const SizedBox(height: 14),
              Pill(p.category.isEmpty ? '기타' : p.category, bg: AppColors.seaSoft, fg: AppColors.seaDeep),
              const SizedBox(height: 8),
              Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
              const SizedBox(height: 6),
              const Text('🧑 익명', style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              if (p.body.isNotEmpty)
                Text(p.body, style: const TextStyle(fontSize: 14, height: 1.65)),
              if (p.aiAnswer != null && p.aiAnswer!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _cmt('✨ AI 도우미', p.aiAnswer!, true),
              ],
              const Divider(height: 28),
              const Text('댓글', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FutureBuilder<List<PostComment>>(
                future: commentsF,
                builder: (c, snap) {
                  final list = snap.data ?? const <PostComment>[];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(8), child: Text('불러오는 중…',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 12)));
                  }
                  if (list.isEmpty) {
                    return const Padding(padding: EdgeInsets.only(bottom: 8),
                        child: Text('아직 댓글이 없어요 · 첫 댓글을 남겨보세요',
                            style: TextStyle(color: AppColors.inkSoft, fontSize: 12)));
                  }
                  return Column(children: list.map((c) => _cmt(c.who, c.body, c.isAi)).toList());
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: input,
                    decoration: InputDecoration(
                      hintText: '따뜻한 댓글을 남겨주세요',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.line, width: 1.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.sea, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.sea,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final text = input.text.trim();
                      if (text.isEmpty) return;
                      final app = context.read<AppState>();
                      final label = '나${app.nationality != null && app.nationality!.isNotEmpty ? ' · ${app.nationality}' : ''}';
                      final ok = await supabase.addComment(p.id, label, text);
                      if (!sheetCtx.mounted) return;
                      if (ok) {
                        input.clear();
                        setSheet(() => commentsF = supabase.fetchComments(p.id));
                      } else {
                        toast(context, '댓글 등록에 실패했어요');
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      child: Text('등록', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
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
