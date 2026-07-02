import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import 'common.dart';

/// 아바타 아이템 상점 (F10에서 확장). 현재: 포인트 배너 + 아이템 그리드 + 배지 + 초대.
void showShopSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ShopSheet(),
  );
}

class _ShopSheet extends StatefulWidget {
  const _ShopSheet();
  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> {
  int cat = 0;
  static const cats = ['피부색', '옷', '모자', '소품'];
  static const items = [
    [ ['🎨', '밝은톤', '사용중'], ['🎨', '중간톤', '무료'], ['🎨', '진한톤', '무료'] ],
    [ ['🧑‍🌾', '농장 작업복', '사용중'], ['🤿', '해녀 잠수복', '300P'], ['🦺', '안전조끼', '200P'] ],
    [ ['🍊', '귤모자', '사용중'], ['🗿', '돌하르방', '300P'], ['👒', '밀짚모자', '200P'] ],
    [ ['🚫', '없음', '사용중'], ['🧺', '감귤바구니', '200P'], ['🌺', '동백꽃', '200P'] ],
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return DraggableScrollableSheet(
      expand: false, initialChildSize: .85, maxChildSize: .92,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(
                color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            const Text('🎨 제주 아이템 상점',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('글을 쓰거나 친구를 초대해 모은 포인트로 내 프로필을 꾸며요.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('🪙 ${app.points} P',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                const Text('글 1개 = +50P · 친구 초대 = +200P',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5)),
              ]),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('🧑‍🌾', style: TextStyle(fontSize: 72))),
            const SizedBox(height: 16),
            Row(
              children: List.generate(cats.length, (i) {
                final on = i == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => cat = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? AppColors.sea : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: on ? AppColors.sea : AppColors.line, width: 1.5),
                      ),
                      child: Text(cats[i],
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: on ? Colors.white : AppColors.inkSoft)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: .95,
              children: items[cat].map((it) {
                final owned = it[2] == '사용중';
                return GestureDetector(
                  onTap: () => toast(context, owned ? '이미 사용 중이에요' : '장착: ${it[1]}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: owned ? AppColors.seaSoft : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: owned ? AppColors.sea : AppColors.line, width: 1.5),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(it[0], style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(it[1], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(it[2], style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700,
                          color: owned ? AppColors.sea : AppColors.seaDeep)),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            BigButton('🎁 친구 초대하고 200P 받기', () {
              Navigator.pop(context);
              toast(context, '초대 링크 복사됨 · 친구 가입 시 +200P (데모)');
            }, color: AppColors.limeDeep),
          ],
        ),
      ),
    );
  }
}
