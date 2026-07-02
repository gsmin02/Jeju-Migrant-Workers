import 'package:flutter/material.dart';
import '../theme.dart';

/// 감귤 로고 마크 (주황 원 + 잎 + 꼭지). 목업 SVG를 CustomPaint로 근사.
class CitrusMark extends StatelessWidget {
  final double size;
  const CitrusMark({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _CitrusPainter()));
}

class _CitrusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final body = Paint()..color = AppColors.sea;
    final bodyStroke = Paint()
      ..color = AppColors.seaDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    // 감귤 본체
    final c = Offset(w * 0.5, h * 0.58);
    final r = w * 0.34;
    canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 1.85), body);
    canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 1.85), bodyStroke);
    // 하이라이트
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.38, h * 0.44), width: w * 0.26, height: w * 0.16),
      Paint()..color = const Color(0xFFFFC562).withValues(alpha: .6),
    );
    // 잎
    final leaf = Paint()..color = AppColors.navy;
    final leafPath = Path()
      ..moveTo(w * 0.52, h * 0.28)
      ..quadraticBezierTo(w * 0.66, h * 0.12, w * 0.82, h * 0.18)
      ..quadraticBezierTo(w * 0.66, h * 0.26, w * 0.60, h * 0.36)
      ..close();
    canvas.drawPath(leafPath, leaf);
    // 꼭지
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.045, Paint()..color = const Color(0xFF7A4F1E));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
