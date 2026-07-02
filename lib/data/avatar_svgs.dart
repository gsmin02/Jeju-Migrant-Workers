/// 아바타 커스터마이징용 SVG 파츠와 합성 함수.
/// jeju_pay 프로토타입(lib/svgs.dart)의 아바타 부분을 이식했다.
/// flutter_svg의 SvgPicture.string으로 렌더링한다.
library;

/// 상점 미리보기(120x130) 모자.
const Map<String, String> kHats = {
  '귤모자':
      '<path d="M32 48 Q60 20 88 48 Q60 40 32 48 Z" fill="#f5a623" stroke="#d98324" stroke-width="2.5"/><path d="M34 48 Q60 57 86 48" fill="#f5a623" stroke="#d98324" stroke-width="2.5"/><path d="M60 24 Q66 14 74 16 Q66 22 63 29 Z" fill="#3f7d4f"/><circle cx="60" cy="26" r="2.5" fill="#8a5a2a"/>',
  '돌하르방':
      '<ellipse cx="60" cy="40" rx="22" ry="15" fill="#8a8580" stroke="#5f5a54" stroke-width="2"/><ellipse cx="60" cy="30" rx="22" ry="6" fill="#9a958f" stroke="#5f5a54" stroke-width="1.5"/><ellipse cx="52" cy="42" rx="4" ry="5" fill="#c4bfb8"/><ellipse cx="68" cy="42" rx="4" ry="5" fill="#c4bfb8"/><circle cx="52" cy="42" r="1.6" fill="#4a4540"/><circle cx="68" cy="42" r="1.6" fill="#4a4540"/>',
  '해녀모자':
      '<path d="M36 44 Q60 26 84 44 Q84 54 60 54 Q36 54 36 44 Z" fill="#2b4a6f" stroke="#1a3350" stroke-width="2"/><circle cx="52" cy="44" r="6" fill="#7fc4d9" opacity=".75" stroke="#1a3350" stroke-width="1"/><circle cx="68" cy="44" r="6" fill="#7fc4d9" opacity=".75" stroke="#1a3350" stroke-width="1"/>',
  '밀짚모자':
      '<ellipse cx="60" cy="46" rx="34" ry="8" fill="#e8c87a" stroke="#c9a94e" stroke-width="1.5"/><path d="M42 46 Q42 28 60 28 Q78 28 78 46 Z" fill="#efd694" stroke="#c9a94e" stroke-width="1.5"/><path d="M42 44 h36" stroke="#c0504a" stroke-width="3"/>',
};

/// 홈 프로필(140x180) 큰 모자.
const Map<String, String> kHatsBig = {
  '귤모자':
      '<path d="M37 72 Q70 58 103 72 Q103 60 70 58 Q37 60 37 72 Z" fill="#c26f1a" opacity=".22"/><path d="M32 70 Q28 32 70 30 Q112 32 108 70 Q108 74 70 74 Q32 74 32 70 Z" fill="#f79c1e"/><ellipse cx="55" cy="46" rx="19" ry="13" fill="#ffc562" opacity=".65"/><path d="M30 70 Q70 82 110 70 Q110 76 70 78 Q30 76 30 70 Z" fill="#f0920f" stroke="#d47d16" stroke-width="1.4"/><circle cx="70" cy="30" r="4.5" fill="#7a4f1e"/><path d="M70 30 Q81 15 96 20 Q83 26 77 35 Z" fill="#3f9750"/>',
  '돌하르방':
      '<ellipse cx="70" cy="52" rx="38" ry="24" fill="#8a8580" stroke="#5f5a54" stroke-width="2.5"/><ellipse cx="70" cy="38" rx="38" ry="10" fill="#9a958f" stroke="#5f5a54" stroke-width="2.5"/><ellipse cx="56" cy="54" rx="7" ry="9" fill="#c4bfb8" stroke="#5f5a54" stroke-width="2"/><ellipse cx="84" cy="54" rx="7" ry="9" fill="#c4bfb8" stroke="#5f5a54" stroke-width="2"/><circle cx="56" cy="55" r="3" fill="#4a4540"/><circle cx="84" cy="55" r="3" fill="#4a4540"/>',
  '동백꽃':
      '<circle cx="70" cy="48" r="21" fill="#e0504a"/><circle cx="52" cy="56" r="12" fill="#d84740"/><circle cx="88" cy="56" r="12" fill="#d84740"/><circle cx="70" cy="48" r="8" fill="#f5d020"/><path d="M48 62 Q37 53 43 42 Q53 49 54 59 Z" fill="#3f7d4f"/>',
  '해녀모자':
      '<path d="M36 58 Q70 32 104 58 Q104 74 70 74 Q36 74 36 58 Z" fill="#2b4a6f" stroke="#1a3350" stroke-width="2.5"/><circle cx="56" cy="58" r="10" fill="#7fc4d9" opacity=".75" stroke="#1a3350" stroke-width="1.5"/><circle cx="84" cy="58" r="10" fill="#7fc4d9" opacity=".75" stroke="#1a3350" stroke-width="1.5"/><path d="M66 58 h8" stroke="#1a3350" stroke-width="1.5"/>',
};

/// 상점 미리보기 옷.
const Map<String, String> kClothes = {
  'farm':
      '<path d="M30 130 Q30 96 60 96 Q90 96 90 130 Z" fill="#4e9a5a"/><path d="M46 98 L46 130 M74 98 L74 130" stroke="#3a7745" stroke-width="3"/><rect x="52" y="106" width="16" height="12" rx="2" fill="#3a7745"/><circle cx="60" cy="112" r="4" fill="#f5a623"/><path d="M60 108 q2 -1.5 3.5 0" stroke="#2f6e3a" stroke-width="1.4" fill="none"/>',
  'haenyeo':
      '<path d="M30 130 Q30 96 60 96 Q90 96 90 130 Z" fill="#1e2b3a"/><path d="M60 96 L60 118" stroke="#7fc4d9" stroke-width="2.5"/><circle cx="60" cy="100" r="2" fill="#7fc4d9"/><path d="M34 120 Q60 126 86 120" stroke="#2b6cb0" stroke-width="3" fill="none"/><path d="M40 104 Q40 100 46 99" stroke="#3a4a5a" stroke-width="2" fill="none"/>',
  'fisher':
      '<path d="M28 130 Q28 94 60 94 Q92 94 92 130 Z" fill="#f2c11e"/><path d="M46 96 Q60 88 74 96 Q60 100 46 96 Z" fill="#e0ad10"/><path d="M60 96 L60 130" stroke="#c99908" stroke-width="2"/><circle cx="60" cy="106" r="1.8" fill="#c99908"/><circle cx="60" cy="116" r="1.8" fill="#c99908"/><path d="M30 122 Q60 128 90 122" stroke="#e0ad10" stroke-width="2.5" fill="none"/>',
  'hanbok':
      '<path d="M30 130 Q30 98 60 98 Q90 98 90 130 Z" fill="#e8f0f5"/><path d="M30 130 Q30 112 44 106 L44 130 Z" fill="#c85a6a"/><path d="M90 130 Q90 112 76 106 L76 130 Z" fill="#5a8ac8"/><path d="M44 100 Q60 108 76 100 L76 106 Q60 112 44 106 Z" fill="#c0504a"/><path d="M60 108 L58 128" stroke="#c0504a" stroke-width="3"/><path d="M60 108 q6 4 5 12" stroke="#c85a6a" stroke-width="2.5" fill="none"/>',
  'vest':
      '<path d="M30 130 Q30 96 60 96 Q90 96 90 130 Z" fill="#eaf24a"/><path d="M60 96 L60 130" stroke="#c9d030" stroke-width="1.5"/><rect x="34" y="112" width="52" height="4" fill="#c8ccd0"/><rect x="34" y="122" width="52" height="4" fill="#c8ccd0"/><path d="M46 98 L46 130 M74 98 L74 130" stroke="#c8ccd0" stroke-width="3"/>',
};

/// 옷 종류 → 홈 프로필(솔리드 상의) 색상.
const Map<String, String> kClothColor = {
  'farm': '#4e9a5a',
  'haenyeo': '#1e2b3a',
  'fisher': '#f2c11e',
  'hanbok': '#e8f0f5',
  'vest': '#eaf24a',
};

/// 홈 프로필(140x180) 큰 소품.
const Map<String, String> kPropsBig = {
  'none': '',
  'basket':
      '<g transform="translate(95,150)"><rect x="0" y="7" width="24" height="17" rx="3" fill="#c98a3a" stroke="#8a5a20" stroke-width="1.5"/><circle cx="6" cy="6" r="5" fill="#f5a623"/><circle cx="17" cy="6" r="5" fill="#f5a623"/><circle cx="11" cy="2" r="5" fill="#f79c1e"/></g>',
  'flower':
      '<g transform="translate(104,118)"><circle cx="0" cy="0" r="9" fill="#e0504a"/><circle cx="0" cy="0" r="3.5" fill="#f5d020"/><path d="M-12 6 Q-18 0 -14 -6 Q-8 -1 -8 4 Z" fill="#3f7d4f"/></g>',
  'rake':
      '<g transform="translate(110,116)"><rect x="0" y="0" width="3" height="40" rx="1.5" fill="#8a5a2a"/><path d="M-7 0 h17 M-7 0 v7 M-1 0 v7 M4 0 v7 M9 0 v7" stroke="#5a3a1a" stroke-width="2.2" fill="none"/></g>',
};

/// 상점 미리보기 소품.
const Map<String, String> kProps = {
  'none': '',
  'basket':
      '<rect x="88" y="98" width="26" height="20" rx="3" fill="#c98a3a" stroke="#8a5a20" stroke-width="1.5"/><circle cx="94" cy="96" r="5" fill="#f5a623"/><circle cx="104" cy="96" r="5" fill="#f5a623"/><circle cx="99" cy="92" r="5" fill="#f79c1e"/>',
  'flower':
      '<circle cx="98" cy="100" r="9" fill="#e0504a"/><circle cx="98" cy="100" r="3.5" fill="#f5d020"/><path d="M86 106 Q80 100 84 94 Q90 99 90 104 Z" fill="#3f7d4f"/>',
  'rake':
      '<rect x="96" y="86" width="3" height="34" rx="1.5" fill="#8a5a2a"/><path d="M90 86 h15 M90 86 v6 M96 86 v6 M104 86 v6" stroke="#5a3a1a" stroke-width="2" fill="none"/>',
};

/// 홈 프로필 모자에 반영 가능한(=HATS_BIG에 있는) 모자 이름.
const List<String> kBigHatNames = ['귤모자', '돌하르방', '동백꽃', '해녀모자'];

/// 상점 미리보기 아바타(120x130) SVG를 현재 장착 상태로 합성.
String buildPreviewAvatarSvg({
  required String skinColor,
  required String clothKind,
  required String hatName,
  required String propKind,
}) {
  final cloth = kClothes[clothKind] ?? kClothes['farm']!;
  final hat = kHats[hatName] ?? kHats['귤모자']!;
  final prop = kProps[propKind] ?? '';
  return '''
<svg viewBox="0 0 120 130" xmlns="http://www.w3.org/2000/svg">
  <g>$cloth</g>
  <rect x="53" y="86" width="14" height="14" rx="5" fill="$skinColor"/>
  <ellipse cx="60" cy="62" rx="24" ry="26" fill="$skinColor"/>
  <circle cx="37" cy="64" r="4.5" fill="$skinColor"/><circle cx="83" cy="64" r="4.5" fill="$skinColor"/>
  <path d="M37 60 Q37 46 60 45 Q83 46 83 60 L83 52 Q60 42 37 52 Z" fill="#3a2e26"/>
  <circle cx="51" cy="64" r="3" fill="#3a2e26"/><circle cx="69" cy="64" r="3" fill="#3a2e26"/>
  <path d="M52 74 Q60 80 68 74" stroke="#b5654a" stroke-width="2.6" fill="none" stroke-linecap="round"/>
  <g>$prop</g>
  <g>$hat</g>
</svg>
''';
}

/// 홈 프로필 캐릭터(140x180) SVG. 상점에서 바꾼 피부색·옷·모자·소품이 모두 반영된다.
String buildProfileAvatarSvg({
  required String hatName,
  String skinColor = '#d69a6a',
  String clothKind = 'farm',
  String propKind = 'none',
}) {
  final hat = kHatsBig[hatName] ?? kHatsBig['귤모자']!;
  final clothColor = kClothColor[clothKind] ?? '#4e9a5a';
  final prop = kPropsBig[propKind] ?? '';
  return '''
<svg viewBox="0 0 140 180" xmlns="http://www.w3.org/2000/svg">
  <path d="M24 180 Q24 134 70 134 Q116 134 116 180 Z" fill="$clothColor"/>
  <g>$prop</g>
  <path d="M56 128 h28 v12 q-14 8 -28 0 Z" fill="$skinColor"/>
  <rect x="61" y="116" width="18" height="20" rx="6" fill="$skinColor"/>
  <ellipse cx="70" cy="88" rx="33" ry="35" fill="$skinColor"/>
  <circle cx="38" cy="90" r="6" fill="$skinColor"/>
  <circle cx="102" cy="90" r="6" fill="$skinColor"/>
  <circle cx="38" cy="90" r="2.5" fill="#b87e50"/>
  <circle cx="102" cy="90" r="2.5" fill="#b87e50"/>
  <path d="M50 82 Q57 79 64 82" stroke="#2a1c12" stroke-width="2.2" fill="none" stroke-linecap="round"/>
  <path d="M76 82 Q83 79 90 82" stroke="#2a1c12" stroke-width="2.2" fill="none" stroke-linecap="round"/>
  <ellipse cx="57" cy="90" rx="4.5" ry="5" fill="#2a1c12"/>
  <ellipse cx="83" cy="90" rx="4.5" ry="5" fill="#2a1c12"/>
  <circle cx="58.5" cy="88.5" r="1.5" fill="#fff"/>
  <circle cx="84.5" cy="88.5" r="1.5" fill="#fff"/>
  <circle cx="49" cy="99" r="5" fill="#c67a52" opacity=".45"/>
  <circle cx="91" cy="99" r="5" fill="#c67a52" opacity=".45"/>
  <path d="M68 92 Q65 101 70 103" stroke="#b87e50" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M59 107 Q70 116 81 107" stroke="#8a4a30" stroke-width="2.8" fill="none" stroke-linecap="round"/>
  <g>$hat</g>
</svg>
''';
}
