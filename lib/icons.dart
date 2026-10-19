import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:path_drawing/path_drawing.dart';

import 'icon_data.dart';

export 'icon_data.dart' show Ic, IconSpec;

final Map<String, ui.Path> _pathCache = {};
ui.Path _path(String d) => _pathCache.putIfAbsent(d, () => parseSvgPathData(d));

/// 목업의 아이콘(SVG)을 그대로 그려요. [size]는 높이, 가로는 아이콘 비율을 따라가요.
class MIcon extends StatelessWidget {
  const MIcon(this.spec, {super.key, this.size, this.width, this.height});

  final IconSpec spec;
  final double? size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final aspect = spec.vb[2] / spec.vb[3];
    final h = height ?? size ?? 24;
    final w = width ?? h * aspect;
    return SizedBox(width: w, height: h, child: CustomPaint(painter: _IconPainter(spec)));
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.spec);
  final IconSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final vb = spec.vb;
    canvas.save();
    canvas.scale(size.width / vb[2], size.height / vb[3]);
    canvas.translate(-vb[0], -vb[1]);
    for (final p in spec.prims) {
      var path = _path(p.d);
      final m = p.m;
      if (m != null) {
        path = path.transform(Float64List.fromList(<double>[
          m[0], m[1], 0, 0, //
          m[2], m[3], 0, 0, //
          0, 0, 1, 0, //
          m[4], m[5], 0, 1,
        ]));
      }
      final sh = p.shadow;
      if (sh != null) {
        canvas.drawPath(
          path.shift(Offset(sh.dx, sh.dy)),
          Paint()
            ..color = sh.color
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, sh.sigma),
        );
      }
      final g = p.grad;
      if (g != null) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..shader = ui.Gradient.linear(Offset(0, g.y0), Offset(0, g.y1), [g.c0, g.c1]),
        );
      } else if (p.fill != null) {
        canvas.drawPath(path, Paint()..style = PaintingStyle.fill..color = p.fill!);
      }
      if (p.stroke != null) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = p.stroke!
            ..strokeWidth = p.sw
            ..strokeCap = p.cap
            ..strokeJoin = p.join,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.spec != spec;
}
