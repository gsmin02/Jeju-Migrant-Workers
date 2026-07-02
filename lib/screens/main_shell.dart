import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../services/supabase_service.dart';
import '../widgets/citrus_mark.dart';
import 'home_tab.dart';
import 'record_tab.dart';
import 'workplace_tab.dart';
import 'community_tab.dart';
import 'sos_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int idx = const int.fromEnvironment('TAB', defaultValue: 0);
  static const _views = ['home', 'record', 'work', 'comm', 'sos'];

  @override
  void initState() {
    super.initState();
    // 로그인 후 진입 시 프로필·근무기록을 DB에서 로드.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().onLoggedIn();
    });
  }

  void goTab(int i) => setState(() => idx = i);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final barKey = 'bar_${_views[idx]}';
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          _body(context, app, barKey),
          if (app.sysNotiTitle != null)
            Positioned(
              top: 0, left: 8, right: 8,
              child: SafeArea(child: _SysNotiBanner(app: app)),
            ),
        ],
      ),
      bottomNavigationBar: _TabBar(idx: idx, onTap: goTab, lang: app.lang),
    );
  }

  Widget _body(BuildContext context, AppState app, String barKey) {
    return Column(
        children: [
          // 상단바
          Container(
            color: AppColors.navy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 11),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24, padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: AppColors.yellow, borderRadius: BorderRadius.circular(7)),
                      child: const CitrusMark(size: 20),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(tr(app.lang, barKey),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.read<AppState>().cycleLang(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text('🌐 ${AppState.langLabels[app.lang]}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => supabase.signOut(), // AuthGate가 로그인 화면으로 전환
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.logout, color: Colors.white70, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 화면
          Expanded(
            child: IndexedStack(
              index: idx,
              children: [
                HomeTab(onGoTab: goTab),
                const RecordTab(),
                const WorkplaceTab(),
                const CommunityTab(),
                const SosTab(),
              ],
            ),
          ),
        ],
      );
  }
}

/// 시스템 알림 배너 (기록 탭 '알림 미리보기' 등에서 표시). 탭하면 닫힘.
class _SysNotiBanner extends StatelessWidget {
  final AppState app;
  const _SysNotiBanner({required this.app});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => app.dismissSysNoti(),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(color: Color(0x1F000000), offset: Offset(0, 4), blurRadius: 16),
          ],
        ),
        child: Row(children: [
          Container(
            width: 34, height: 34, padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                color: AppColors.yellow, borderRadius: BorderRadius.circular(9)),
            child: const CitrusMark(size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.sysNotiTitle ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(app.sysNotiText ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int idx;
  final ValueChanged<int> onTap;
  final String lang;
  const _TabBar({required this.idx, required this.onTap, required this.lang});

  static const _keys = ['tab_home', 'tab_record', 'tab_work', 'tab_comm', 'tab_sos'];
  static const _icons = ['🍊', '📋', '🏢', '💬', '🆘'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 6),
          child: Row(
            children: List.generate(5, (i) {
              final active = i == idx;
              final isSos = i == 4;
              final color = active
                  ? (isSos ? AppColors.red : AppColors.seaDeep)
                  : AppColors.inkSoft;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: active ? 1 : .5,
                        child: Text(_icons[i], style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 3),
                      Text(tr(lang, _keys[i]),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
