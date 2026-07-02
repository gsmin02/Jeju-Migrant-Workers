import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../state/app_state.dart';
import '../state/i18n.dart';
import '../data/avatar_svgs.dart';
import 'common.dart';

/// 아바타 아이템 상점. 피부색·옷·모자·소품을 골라 프로필 캐릭터를 꾸민다.
/// 장착 상태는 AppState → Supabase profiles에 저장된다.
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

/// 상점 아이템 정의: 식별자(장착값)·이모지·스와치·이름키·가격라벨.
class _ShopItem {
  const _ShopItem(this.value, {this.emoji, this.swatch, required this.nameKey, this.cost = ''});
  final String value;
  final String? emoji;
  final Color? swatch;
  final String nameKey;
  final String cost;
}

class _ShopSheet extends StatefulWidget {
  const _ShopSheet();
  @override
  State<_ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends State<_ShopSheet> {
  String cat = 'skin';

  static const _cats = [
    ('skin', 'cat_skin'),
    ('cloth', 'cat_cloth'),
    ('hat', 'cat_hat'),
    ('prop', 'cat_prop'),
  ];

  static const _skins = [
    _ShopItem('#f0c093', swatch: Color(0xFFF8D9B0), nameKey: 'sk_light'),
    _ShopItem('#e0ac7d', swatch: Color(0xFFE8B587), nameKey: 'sk_mid'),
    _ShopItem('#c98a5a', swatch: Color(0xFFD69A6A), nameKey: 'sk_tan'),
    _ShopItem('#a86a3c', swatch: Color(0xFFB87E50), nameKey: 'sk_dark'),
    _ShopItem('#8a5230', swatch: Color(0xFF9A6440), nameKey: 'sk_darker'),
  ];
  static const _clothes = [
    _ShopItem('farm', emoji: '🧑‍🌾', nameKey: 'cl_farm'),
    _ShopItem('haenyeo', emoji: '🤿', nameKey: 'cl_haenyeo', cost: '300P'),
    _ShopItem('fisher', emoji: '🎣', nameKey: 'cl_fisher', cost: '300P'),
    _ShopItem('hanbok', emoji: '👘', nameKey: 'cl_hanbok', cost: '400P'),
    _ShopItem('vest', emoji: '🦺', nameKey: 'cl_vest', cost: '200P'),
  ];
  static const _hats = [
    _ShopItem('귤모자', emoji: '🍊', nameKey: 'ht_gyul'),
    _ShopItem('돌하르방', emoji: '🗿', nameKey: 'ht_dol', cost: '300P'),
    _ShopItem('해녀모자', emoji: '🥽', nameKey: 'ht_haenyeo', cost: '500P'),
    _ShopItem('밀짚모자', emoji: '👒', nameKey: 'ht_straw', cost: '200P'),
  ];
  static const _propsList = [
    _ShopItem('none', emoji: '🚫', nameKey: 'pr_none'),
    _ShopItem('basket', emoji: '🧺', nameKey: 'pr_basket', cost: '200P'),
    _ShopItem('flower', emoji: '🌺', nameKey: 'pr_flower', cost: '200P'),
    _ShopItem('rake', emoji: '🍃', nameKey: 'pr_rake', cost: '300P'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lang = app.lang;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      maxChildSize: .95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.line, borderRadius: BorderRadius.circular(99)))),
            const SizedBox(height: 14),
            Text('🎨 ${tr(lang, 'shop_title')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(tr(lang, 'shop_sub'),
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.4)),
            const SizedBox(height: 14),
            // 포인트 배너
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration:
                  BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('🪙 ${app.points} P',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(tr(lang, 'shop_how'),
                    style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
              ]),
            ),
            const SizedBox(height: 16),
            // 아바타 미리보기 (실시간 반영)
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.sea, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33F5A623), offset: Offset(0, 3), blurRadius: 10),
                  ],
                ),
                child: SvgPicture.string(
                  buildPreviewAvatarSvg(
                    skinColor: app.skinColor,
                    clothKind: app.clothKind,
                    hatName: app.hatName,
                    propKind: app.propKind,
                  ),
                  width: 96,
                  height: 104,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 카테고리 탭
            Row(
              children: List.generate(_cats.length, (i) {
                final key = _cats[i].$1;
                final on = key == cat;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => cat = key),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: on ? AppColors.sea : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: on ? AppColors.sea : AppColors.line, width: 1.5),
                      ),
                      child: Text(tr(lang, _cats[i].$2),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: on ? Colors.white : AppColors.inkSoft)),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            _buildGrid(context, app),
            const SizedBox(height: 16),
            BigButton('🎁 ${tr(lang, 'shop_invite')}', () {
              Navigator.pop(context);
              toast(context, tr(lang, 'shop_invite_toast'));
            }, color: AppColors.limeDeep),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, AppState app) {
    final lang = app.lang;
    final List<_ShopItem> items;
    bool Function(_ShopItem) equipped;
    void Function(_ShopItem) equip;
    switch (cat) {
      case 'cloth':
        items = _clothes;
        equipped = (it) => app.clothKind == it.value;
        equip = (it) => app.equipCloth(it.value);
      case 'hat':
        items = _hats;
        equipped = (it) => app.hatName == it.value;
        equip = (it) => app.equipHat(it.value);
      case 'prop':
        items = _propsList;
        equipped = (it) => app.propKind == it.value;
        equip = (it) => app.equipProp(it.value);
      default: // skin
        items = _skins;
        equipped = (it) => app.skinColor == it.value;
        equip = (it) => app.equipSkin(it.value);
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: .95,
      children: items.map((it) {
        final on = equipped(it);
        final name = tr(lang, it.nameKey);
        return GestureDetector(
          onTap: () {
            if (on) return;
            equip(it);
            toast(context, '${tr(lang, 'toast_equip')}$name');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: on ? AppColors.seaSoft : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? AppColors.sea : AppColors.line, width: 1.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (it.swatch != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: it.swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x14000000), width: 2),
                  ),
                )
              else
                Text(it.emoji ?? '', style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 4),
              Text(name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              if (on)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration:
                      BoxDecoration(color: AppColors.sea, borderRadius: BorderRadius.circular(20)),
                  child: Text(tr(lang, 'item_using'),
                      style: const TextStyle(
                          fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700)),
                )
              else
                Text(it.cost.isEmpty ? tr(lang, 'item_free') : it.cost,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.seaDeep, fontWeight: FontWeight.w700)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
