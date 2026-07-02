import 'package:flutter/material.dart';

/// 목업 CSS 변수 → Dart 팔레트 (감귤·잎초록 테마)
class AppColors {
  static const navy = Color(0xFF3F7D4F); // 잎사귀 초록 (상단바)
  static const navyDeep = Color(0xFF2E5C3A);
  static const sea = Color(0xFFF5A623); // 감귤 주황
  static const seaSoft = Color(0xFFFDF0D5);
  static const seaDeep = Color(0xFFD98324);
  static const lime = Color(0xFFC3E88D);
  static const limeSoft = Color(0xFFEAF6D4);
  static const limeDeep = Color(0xFF7CB342);
  static const yellow = Color(0xFFFDF6C9);
  static const sand = Color(0xFFFBF3DD);
  static const paper = Color(0xFFFFFDF5);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFECE5D0);
  static const ink = Color(0xFF3A3226);
  static const inkSoft = Color(0xFF8A7F6A);
  static const amber = Color(0xFFD98324);
  static const amberSoft = Color(0xFFFBEDD9);
  static const red = Color(0xFFE05A4A);
  static const redSoft = Color(0xFFFBEAE7);
  static const green = Color(0xFF7CB342);
  static const greenSoft = Color(0xFFEAF6D4);
}

/// 공통 그림자 (목업 --shadow)
const kCardShadow = [
  BoxShadow(color: Color(0x14785032), blurRadius: 3, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x12785032), blurRadius: 18, offset: Offset(0, 6)),
];

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sea,
      primary: AppColors.sea,
      surface: AppColors.paper,
    ),
    scaffoldBackgroundColor: AppColors.paper,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
