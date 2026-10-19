import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

/// 뭐먹어? 전용 아이콘. 하루링 아이콘처럼 끝이 둥근 선으로 그려요.
enum Glyph { fork, calendar, sunrise, sun, moon, camera, people, bell }

class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, this.size, this.color, this.stroke = 1.9});
  final Glyph glyph;
  final double? size;
  final Color? color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    final c = color ?? theme.color ?? const Color(0xFF23244A);
    return SizedBox(width: s, height: s, child: CustomPaint(painter: _GlyphPainter(glyph, c, stroke)));
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, this.stroke);
  final Glyph glyph;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    canvas.scale(k);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) => canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    void rrect(double l, double t, double r, double b, double rad) =>
        canvas.drawRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)), p);
    void circle(double x, double y, double r) => canvas.drawCircle(Offset(x, y), r, p);

    switch (glyph) {
      case Glyph.fork:
        // 포크
        final fork = Path()
          ..moveTo(5.5, 3.5)
          ..lineTo(5.5, 8.5)
          ..arcToPoint(const Offset(11.5, 8.5), radius: const Radius.circular(3), clockwise: false)
          ..lineTo(11.5, 3.5);
        canvas.drawPath(fork, p);
        line(8.5, 3.5, 8.5, 9.5);
        line(8.5, 11.5, 8.5, 20.5);
        // 숟가락
        canvas.drawOval(Rect.fromCenter(center: const Offset(16.5, 7.4), width: 5.4, height: 8.4), p);
        line(16.5, 11.8, 16.5, 20.5);
      case Glyph.calendar:
        rrect(3.8, 5.2, 20.2, 20.4, 3.6);
        line(3.8, 10.2, 20.2, 10.2);
        line(8.4, 3, 8.4, 6.6);
        line(15.6, 3, 15.6, 6.6);
        // 가운데 점 (밥 먹은 날 표시)
        canvas.drawRRect(
            RRect.fromLTRBR(9.3, 13.2, 14.7, 17.2, const Radius.circular(1.4)), Paint()..color = color);
      case Glyph.sunrise:
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 16.5), radius: 4.6), math.pi, math.pi, false, p);
        line(3.5, 19.8, 20.5, 19.8);
        line(12, 5.5, 12, 7.8);
        line(4.8, 9.6, 6.5, 11.2);
        line(19.2, 9.6, 17.5, 11.2);
      case Glyph.sun:
        circle(12, 12, 4.2);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(12 + 7.2 * math.cos(a), 12 + 7.2 * math.sin(a), 12 + 9.4 * math.cos(a), 12 + 9.4 * math.sin(a));
        }
      case Glyph.moon:
        final moon = Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: const Offset(11.5, 12.5), radius: 8)),
          Path()..addOval(Rect.fromCircle(center: const Offset(16.5, 8.5), radius: 7.2)),
        );
        canvas.drawPath(moon, p);
      case Glyph.camera:
        rrect(3, 7.2, 21, 20.4, 3.8);
        final bump = Path()
          ..moveTo(8.4, 7.2)
          ..lineTo(9.8, 4.6)
          ..lineTo(14.2, 4.6)
          ..lineTo(15.6, 7.2);
        canvas.drawPath(bump, p);
        circle(12, 13.8, 3.6);
      case Glyph.people:
        circle(9.2, 8.4, 3.2);
        final body = Path()
          ..moveTo(3.4, 19.6)
          ..cubicTo(3.4, 16.2, 6, 14.4, 9.2, 14.4)
          ..cubicTo(12.4, 14.4, 15, 16.2, 15, 19.6);
        canvas.drawPath(body, p);
        circle(17.2, 9.4, 2.5);
        final body2 = Path()
          ..moveTo(16.6, 14.5)
          ..cubicTo(19.2, 14.6, 20.8, 16.4, 20.8, 19.2);
        canvas.drawPath(body2, p);
      case Glyph.bell:
        final bell = Path()
          ..moveTo(6, 16.6)
          ..lineTo(6, 11)
          ..arcToPoint(const Offset(18, 11), radius: const Radius.circular(6))
          ..lineTo(18, 16.6)
          ..lineTo(19.6, 18.2)
          ..lineTo(4.4, 18.2)
          ..close();
        canvas.drawPath(bell, p);
        final clap = Path()
          ..moveTo(10, 21)
          ..arcToPoint(const Offset(14, 21), radius: const Radius.circular(2), clockwise: false);
        canvas.drawPath(clap, p);
        line(12, 3.6, 12, 5);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.glyph != glyph || old.color != color || old.stroke != stroke;
}
