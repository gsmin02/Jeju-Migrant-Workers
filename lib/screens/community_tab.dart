import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../services/supabase_service.dart';
import '../services/translate_service.dart';
import '../widgets/common.dart';
import '../widgets/paywall_sheet.dart';

/// DB에 저장된 한국어 카테고리 값을 현재 언어 라벨로 변환.
String _catLabel(String lang, String cat) {
  const m = {
    '임금체불': 'cat_wage', '계약': 'cat_contract', '비자': 'cat_visa',
    '제주생활': 'cat_life', '기타': 'cat_etc',
  };
  final k = m[cat];
  return k != null ? tr(lang, k) : (cat.isEmpty ? tr(lang, 'cat_etc') : cat);
}

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});
  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  bool hot = true;
  late Future<List<CommunityPost>> _future;

  // ----- 번역 상태 -----
  final Map<String, Map<String, String>> _tr = {}; // 'postId|lang' → {title,body,ai_answer}
  final Set<String> _showTr = {}; // 번역을 보여주는 postId
  final Set<String> _loadingTr = {}; // 번역 로딩 중인 postId

  // ----- 좋아요 상태 -----
  final Set<String> _liked = {}; // 내가 좋아요한 postId
  final Map<String, int> _likes = {}; // postId → 표시용 좋아요 수(오버라이드)

  /// 귤(좋아요) 토글: DB(toggle_like RPC) 반영, 실패 시 로컬 낙관적 토글.
  Future<void> _toggleLike(CommunityPost p) async {
    final res = await supabase.toggleLike(p.id);
    if (!mounted) return;
    if (res != null && res['ok'] == true) {
      setState(() {
        if (res['liked'] == true) {
          _liked.add(p.id);
        } else {
          _liked.remove(p.id);
        }
        _likes[p.id] = (res['likes'] ?? p.likes) as int;
      });
    } else {
      // DB 미연결/마이그레이션 전 — 로컬 낙관적 토글(하트 표시)
      setState(() {
        final base = _likes[p.id] ?? p.likes;
        if (_liked.contains(p.id)) {
          _liked.remove(p.id);
          _likes[p.id] = base - 1;
        } else {
          _liked.add(p.id);
          _likes[p.id] = base + 1;
        }
      });
    }
  }

  /// 글 번역 토글: 캐시(DB) → 없으면 AI 번역 후 DB 캐시 저장.
  Future<void> _toggleTranslate(CommunityPost p, String lang) async {
    final key = '${p.id}|$lang';
    if (_showTr.contains(p.id)) {
      setState(() => _showTr.remove(p.id));
      return;
    }
    if (_tr.containsKey(key)) {
      setState(() => _showTr.add(p.id));
      return;
    }
    setState(() => _loadingTr.add(p.id));
    // 1) DB 캐시 먼저
    Map<String, String>? t = await supabase.fetchTranslation(p.id, lang);
    // 2) 없으면 AI 번역 후 캐시에 저장
    if (t == null) {
      final out = await translateService.translate([p.title, p.body, p.aiAnswer ?? ''], lang);
      if (out != null && out.length == 3) {
        t = {'title': out[0], 'body': out[1], 'ai_answer': out[2]};
        await supabase.saveTranslation(p.id, lang,
            title: out[0], body: out[1], aiAnswer: out[2]);
      }
    }
    if (!mounted) return;
    setState(() {
      _loadingTr.remove(p.id);
      if (t != null) {
        _tr[key] = t;
        _showTr.add(p.id);
      }
    });
    if (t == null && mounted) toast(context, tr(lang, 'tr_fail'));
  }

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
        if (!app.previewPaid) _freeBadge(tr(app.lang, 'comm_free_badge')),
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
              Expanded(
                child: Text(tr(app.lang, 'comm_ask'),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          _sortTab(tr(app.lang, 'sort_hot'), hot, () => _setSort(true)),
          const SizedBox(width: 8),
          _sortTab(tr(app.lang, 'sort_new'), !hot, () => _setSort(false)),
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(tr(app.lang, 'comm_empty'),
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ),
              );
            }
            final pinned = posts.where((p) => p.pinned).toList();
            final rest = posts.where((p) => !p.pinned).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (pinned.isNotEmpty) ...[
                Text(tr(app.lang, 'pin_label'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                const SizedBox(height: 8),
                ...pinned.map((p) => _postCard(context, p)),
              ],
              SectionLabel(tr(app.lang, hot ? 'comm_hot_label' : 'comm_new_label')),
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
    final lang = context.read<AppState>().lang;
    final showing = _showTr.contains(p.id);
    final loading = _loadingTr.contains(p.id);
    final t = showing ? _tr['${p.id}|$lang'] : null;
    final title = t != null ? t['title']! : p.title;
    final body = t != null ? t['body']! : p.body;
    final ai = t != null ? t['ai_answer']! : (p.aiAnswer ?? '');
    // 원문이 한국어라고 보고, 다른 언어일 때만 번역 버튼 노출.
    final canTranslate = lang != 'ko';
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
            Pill(_catLabel(lang, p.category), bg: AppColors.seaSoft, fg: AppColors.seaDeep),
            const Spacer(),
            // 귤 좋아요 — 누르면 옆에 하트가 붙음
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleLike(p),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🍊 ${_likes[p.id] ?? p.likes}',
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                if (_liked.contains(p.id))
                  const Padding(
                    padding: EdgeInsets.only(left: 3),
                    child: Text('💕', style: TextStyle(fontSize: 12)),
                  ),
              ]),
            ),
          ]),
          const SizedBox(height: 7),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(body, style: const TextStyle(fontSize: 12.5, color: Color(0xFF3A4A55), height: 1.4)),
          ],
          if (ai.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.seaSoft, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(lang, 'ai_who'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                const SizedBox(height: 3),
                Text(ai, style: const TextStyle(fontSize: 12, height: 1.4)),
              ]),
            ),
          ],
          if (canTranslate) ...[
            const SizedBox(height: 9),
            Row(children: [
              // 내부 탭이 카드 탭(상세 열기)으로 전파되지 않도록 별도 GestureDetector.
              GestureDetector(
                onTap: loading ? null : () => _toggleTranslate(p, lang),
                child: Text(
                  loading
                      ? '🌐 ${tr(lang, 'tr_loading')}'
                      : showing
                          ? '🔙 ${tr(lang, 'tr_orig')}'
                          : '🌐 ${tr(lang, 'tr_show')}',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.seaDeep),
                ),
              ),
              if (showing) ...[
                const SizedBox(width: 8),
                Text('· ${tr(lang, 'tr_by_ai')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
              ],
            ]),
          ],
        ]),
      ),
    );
  }

  void _openWrite(BuildContext context) {
    final lang = context.read<AppState>().lang;
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
            Text(tr(lang, 'write_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, children: [
              for (final c in cats)
                GestureDetector(
                  onTap: () => setSheet(() => category = c),
                  child: Pill(_catLabel(lang, c),
                      bg: category == c ? AppColors.sea : AppColors.seaSoft,
                      fg: category == c ? Colors.white : AppColors.seaDeep),
                ),
            ]),
            const SizedBox(height: 10),
            TextField(controller: titleC,
                decoration: InputDecoration(hintText: tr(lang, 'write_title_ph'), border: const OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: bodyC, maxLines: 4,
                decoration: InputDecoration(hintText: tr(lang, 'write_body_ph'), border: const OutlineInputBorder())),
            const SizedBox(height: 14),
            BigButton(tr(lang, 'write_submit'), () async {
              final title = titleC.text.trim();
              if (title.isEmpty) {
                toast(context, tr(lang, 'write_need_title'));
                return;
              }
              final err = await supabase.addPost(category, title, bodyC.text.trim());
              if (!sheetCtx.mounted) return;
              Navigator.pop(sheetCtx);
              if (err != null) {
                toast(context, err);
              } else {
                context.read<AppState>().awardPoints(5); // 글 작성 +5P
                toast(context, tr(lang, 'write_done'));
                _reload();
              }
            }),
          ]),
        ),
      ),
    );
  }

  void _openPost(BuildContext context, CommunityPost p) {
    final lang = context.read<AppState>().lang;
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
              Pill(_catLabel(lang, p.category), bg: AppColors.seaSoft, fg: AppColors.seaDeep),
              const SizedBox(height: 8),
              Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.4)),
              const SizedBox(height: 6),
              Text(tr(lang, 'post_anon'), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              if (p.body.isNotEmpty)
                Text(p.body, style: const TextStyle(fontSize: 14, height: 1.65)),
              if (p.aiAnswer != null && p.aiAnswer!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _cmt(tr(lang, 'ai_who'), p.aiAnswer!, true),
              ],
              const Divider(height: 28),
              Text(tr(lang, 'cmt_label'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              FutureBuilder<List<PostComment>>(
                future: commentsF,
                builder: (c, snap) {
                  final list = snap.data ?? const <PostComment>[];
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Padding(padding: const EdgeInsets.all(8), child: Text(tr(lang, 'cmt_loading'),
                        style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)));
                  }
                  if (list.isEmpty) {
                    return Padding(padding: const EdgeInsets.only(bottom: 8),
                        child: Text(tr(lang, 'cmt_empty'),
                            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)));
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
                      hintText: tr(lang, 'cmt_ph'),
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
                      final label = '${tr(lang, 'cmt_me')}${app.nationality != null && app.nationality!.isNotEmpty ? ' · ${app.nationality}' : ''}';
                      final ok = await supabase.addComment(p.id, label, text);
                      if (!sheetCtx.mounted) return;
                      if (ok) {
                        input.clear();
                        setSheet(() => commentsF = supabase.fetchComments(p.id));
                      } else {
                        toast(context, tr(lang, 'cmt_err'));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      child: Text(tr(lang, 'cmt_send'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
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
