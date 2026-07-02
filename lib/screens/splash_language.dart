import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../widgets/citrus_mark.dart';
import '../widgets/common.dart';

class SplashLanguageScreen extends StatelessWidget {
  final VoidCallback onPicked;
  const SplashLanguageScreen({super.key, required this.onPicked});

  static const _langs = [
    ['ko', '한국어', true], ['ne', 'नेपाली', false],
    ['id', 'Bahasa', true], ['si', 'සිංහල', false],
    ['km', 'ខ្មែរ', false], ['vi', 'Tiếng Việt', true],
    ['en', 'English', true], ['th', 'ไทย', false],
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFFDF6C9), Color(0xFFFDE3C0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 112, height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(color: Color(0x38B48C3C), blurRadius: 16, offset: Offset(0, 6)),
                      ],
                    ),
                    child: const Center(child: CitrusMark(size: 76)),
                  ),
                  const SizedBox(height: 16),
                  const Text('제이',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.seaDeep)),
                  const SizedBox(height: 2),
                  const Text('제주 이주민 · Jeju Migrant Workers',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  const SizedBox(height: 22),
                  const Text('언어를 선택하세요',
                      style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 2.7,
                    children: _langs.map((l) {
                      final code = l[0] as String, name = l[1] as String, ready = l[2] as bool;
                      return _LangButton(name: name, onTap: () {
                        if (ready) {
                          app.setLang(code);
                        } else {
                          app.setLang('en');
                          toast(context, '$name — 번역 준비 중입니다. 임시로 English로 표시해요');
                        }
                        onPicked();
                      });
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text('나중에 상단에서 언제든 바꿀 수 있어요',
                      style: TextStyle(fontSize: 11, color: Color(0xFFA8997A))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _LangButton({required this.name, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF0E4BF), width: 1.5),
            ),
            child: Text(name,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ),
      );
}
