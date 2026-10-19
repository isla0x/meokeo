// 자동 생성 파일이에요. 목업(SVG)의 아이콘 도형을 그대로 옮겼어요. 직접 고치지 마세요.
import 'dart:ui' show Color, StrokeCap, StrokeJoin;

class IconGrad {
  const IconGrad(this.y0, this.y1, this.c0, this.c1);
  final double y0, y1;
  final Color c0, c1;
}

class IconShadow {
  const IconShadow(this.dx, this.dy, this.sigma, this.color);
  final double dx, dy, sigma;
  final Color color;
}

class IconPrim {
  const IconPrim(this.d, {this.fill, this.stroke, this.sw = 1, this.cap = StrokeCap.butt, this.join = StrokeJoin.miter, this.m, this.grad, this.shadow});
  final String d;
  final Color? fill;
  final Color? stroke;
  final double sw;
  final StrokeCap cap;
  final StrokeJoin join;
  final List<double>? m;
  final IconGrad? grad;
  final IconShadow? shadow;
}

class IconSpec {
  const IconSpec(this.vb, this.prims);
  final List<double> vb; // x, y, 너비, 높이
  final List<IconPrim> prims;
}

const IconGrad _tealGrad = IconGrad(-30, 30, Color(0xFF5A6A66), Color(0xFF14201E));
const IconShadow _tealShadow = IconShadow(0, 3, 2.6, Color(0x571F6B66));

abstract final class Ic {
  static const sunrise = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M5.8 17.2a6.2 6.2 0 0 1 12.4 0z', fill: Color(0xFFFFFFFF)),
    IconPrim('M12 4.6v2.6M4.7 8.7l1.9 1.9M19.3 8.7l-1.9 1.9M2.6 17.2h1.8M19.6 17.2h1.8', stroke: Color(0xFFFFFFFF), sw: 1.9, cap: StrokeCap.round, join: StrokeJoin.round),
    IconPrim('M5 20.6h14', stroke: Color(0xB2FFFFFF), sw: 1.8, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const sun = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.5 12A4.5 4.5 0 1 0 16.5 12A4.5 4.5 0 1 0 7.5 12Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M12 2.9v2.4M12 18.7v2.4M2.9 12h2.4M18.7 12h2.4M5.6 5.6l1.7 1.7M16.7 16.7l1.7 1.7M18.4 5.6l-1.7 1.7M7.3 16.7l-1.7 1.7', stroke: Color(0xFFFFFFFF), sw: 1.9, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const moon = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M19.6 14.8A8.2 8.2 0 0 1 9.2 4.4a8.2 8.2 0 1 0 10.4 10.4z', fill: Color(0xFFFFFFFF), m: <double>[0.95, 0, 0, 0.95, -1.6, 1.4]),
    IconPrim('M17.6 3.6l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z', fill: Color(0xFFFFFFFF)),
    IconPrim('M20.2 11.2l.45 1.1 1.1.45-1.1.45-.45 1.1-.45-1.1-1.1-.45 1.1-.45z', fill: Color(0xD9FFFFFF)),
  ]);

  static const peopleDuo = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M14.4 9A2.8 2.8 0 1 0 20 9A2.8 2.8 0 1 0 14.4 9Z', fill: Color(0xFF14201E)),
    IconPrim('M15.2 14.1c.7-.2 1.4-.3 2.1-.3 2.8 0 4.6 1.9 4.6 5.2h-4.8c0-2.2-.6-3.9-1.9-4.9z', fill: Color(0xFF14201E)),
    IconPrim('M5.5 8.6A3.5 3.5 0 1 0 12.5 8.6A3.5 3.5 0 1 0 5.5 8.6Z', fill: Color(0xFF1C1C1E), stroke: Color(0xFFFFFFFF), sw: 1.2, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M2.6 19.6c0-3.8 2.8-6 6.4-6s6.4 2.2 6.4 6z', fill: Color(0xFF1C1C1E), stroke: Color(0xFFFFFFFF), sw: 1.2, cap: StrokeCap.butt, join: StrokeJoin.round),
  ]);

  static const bell = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M6 16.2v-5a6 6 0 0 1 12 0v5l1.5 2H4.5z', fill: Color(0x121C1C1E), stroke: Color(0xFF1C1C1E), sw: 1.8, cap: StrokeCap.butt, join: StrokeJoin.round),
    IconPrim('M10 20.8a2 2 0 0 0 4 0', stroke: Color(0xFF1C1C1E), sw: 1.8, cap: StrokeCap.round, join: StrokeJoin.round),
    IconPrim('M14.7 5.6A3.3 3.3 0 1 0 21.3 5.6A3.3 3.3 0 1 0 14.7 5.6Z', fill: Color(0xFF14201E), stroke: Color(0xFFFFFFFF), sw: 1.5, cap: StrokeCap.butt, join: StrokeJoin.miter),
  ]);

  static const bellPlain = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M6 16.2v-5a6 6 0 0 1 12 0v5l1.5 2H4.5z', fill: Color(0x121C1C1E), stroke: Color(0xFF1C1C1E), sw: 1.8, cap: StrokeCap.butt, join: StrokeJoin.round),
    IconPrim('M10 20.8a2 2 0 0 0 4 0', stroke: Color(0xFF1C1C1E), sw: 1.8, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const bowlOn = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M3 11.2h18c0 5-4 9-9 9s-9-4-9-9z', fill: Color(0xFF14201E)),
    IconPrim('M3.4 12.6h17.2', fill: Color(0xD9000000), stroke: Color(0xD9FFFFFF), sw: 1.2, cap: StrokeCap.round, join: StrokeJoin.miter),
    IconPrim('M8 7.2c0-1.1 1-1.5 1-2.7M12 7.2c0-1.1 1-1.5 1-2.7M16 7.2c0-1.1 1-1.5 1-2.7', stroke: Color(0xFF14201E), sw: 1.7, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const bowlOff = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M3.4 11.6h17.2c0 4.7-3.8 8.4-8.6 8.4s-8.6-3.7-8.6-8.4z', fill: Color(0x338E8E93), stroke: Color(0xFF48484A), sw: 1.7, cap: StrokeCap.butt, join: StrokeJoin.round),
    IconPrim('M8 7.2c0-1.1 1-1.5 1-2.7M12 7.2c0-1.1 1-1.5 1-2.7M16 7.2c0-1.1 1-1.5 1-2.7', stroke: Color(0xFF48484A), sw: 1.7, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const calOn = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.6 4.8H16.4A4.2 4.2 0 0 1 20.6 9V16.8A4.2 4.2 0 0 1 16.4 21H7.6A4.2 4.2 0 0 1 3.4 16.8V9A4.2 4.2 0 0 1 7.6 4.8Z', fill: Color(0xFF14201E)),
    IconPrim('M3.4 10.2h17.2', fill: Color(0xD9000000), stroke: Color(0xD9FFFFFF), sw: 1.2, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M8.2 2.8v3.6M15.8 2.8v3.6', stroke: Color(0xFF14201E), sw: 2, cap: StrokeCap.round, join: StrokeJoin.round),
    IconPrim('M6.5 15.6A1.5 1.5 0 1 0 9.5 15.6A1.5 1.5 0 1 0 6.5 15.6Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M10.5 15.6A1.5 1.5 0 1 0 13.5 15.6A1.5 1.5 0 1 0 10.5 15.6Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M14.5 15.6A1.5 1.5 0 1 0 17.5 15.6A1.5 1.5 0 1 0 14.5 15.6Z', fill: Color(0xFFFFFFFF)),
  ]);

  static const calOff = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.6 5.2H16.4A4 4 0 0 1 20.4 9.2V16.6A4 4 0 0 1 16.4 20.6H7.6A4 4 0 0 1 3.6 16.6V9.2A4 4 0 0 1 7.6 5.2Z', fill: Color(0x298E8E93), stroke: Color(0xFF48484A), sw: 1.7, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M3.6 10.2h16.8M8.2 3.2v3.6M15.8 3.2v3.6', stroke: Color(0xFF48484A), sw: 1.7, cap: StrokeCap.round, join: StrokeJoin.round),
    IconPrim('M6.6 15.4A1.4 1.4 0 1 0 9.4 15.4A1.4 1.4 0 1 0 6.6 15.4Z', fill: Color(0xFF8E8E93)),
    IconPrim('M10.6 15.4A1.4 1.4 0 1 0 13.4 15.4A1.4 1.4 0 1 0 10.6 15.4Z', fill: Color(0xFF8E8E93)),
    IconPrim('M14.6 15.4A1.4 1.4 0 1 0 17.4 15.4A1.4 1.4 0 1 0 14.6 15.4Z', fill: Color(0xFF8E8E93)),
  ]);

  static const camera = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M3.6 9A3 3 0 0 1 6.6 6h1l1.2-2h6.4l1.2 2h1A3 3 0 0 1 20.4 9v7.6a3 3 0 0 1-3 3H6.6a3 3 0 0 1-3-3z', fill: Color(0xFF636366)),
    IconPrim('M7.4 12.8A4.6 4.6 0 1 0 16.6 12.8A4.6 4.6 0 1 0 7.4 12.8Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M9 12.8A3 3 0 1 0 15 12.8A3 3 0 1 0 9 12.8Z', fill: Color(0xFF14201E)),
    IconPrim('M9.9 11.6A0.9 0.9 0 1 0 11.7 11.6A0.9 0.9 0 1 0 9.9 11.6Z', fill: Color(0xD9FFFFFF)),
    IconPrim('M16.7 9A0.9 0.9 0 1 0 18.5 9A0.9 0.9 0 1 0 16.7 9Z', fill: Color(0xCCFFFFFF)),
  ]);

  static const lock = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.8 10.5H16.2A2.8 2.8 0 0 1 19 13.3V17.7A2.8 2.8 0 0 1 16.2 20.5H7.8A2.8 2.8 0 0 1 5 17.7V13.3A2.8 2.8 0 0 1 7.8 10.5Z', fill: Color(0xFF6C6C70)),
    IconPrim('M8.2 10.5V8a3.8 3.8 0 0 1 7.6 0v2.5', stroke: Color(0xFF6C6C70), sw: 2, cap: StrokeCap.round, join: StrokeJoin.miter),
  ]);

  static const lockLight = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.8 10.5H16.2A2.8 2.8 0 0 1 19 13.3V17.7A2.8 2.8 0 0 1 16.2 20.5H7.8A2.8 2.8 0 0 1 5 17.7V13.3A2.8 2.8 0 0 1 7.8 10.5Z', fill: Color(0xFF8E8E93)),
    IconPrim('M8.2 10.5V8a3.8 3.8 0 0 1 7.6 0v2.5', stroke: Color(0xFF8E8E93), sw: 2, cap: StrokeCap.round, join: StrokeJoin.miter),
  ]);

  static const chevLeft = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M14.5 5.5L8 12l6.5 6.5', stroke: Color(0xFF1C1C1E), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const chevLeftGray = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M14.5 5.5L8 12l6.5 6.5', stroke: Color(0xFF6C6C70), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const chevRightGray = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M9.5 5.5L16 12l-6.5 6.5', stroke: Color(0xFF6C6C70), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const clock = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M3.5 12A8.5 8.5 0 1 0 20.5 12A8.5 8.5 0 1 0 3.5 12Z', stroke: Color(0xFF1C1C1E), sw: 2, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M12 7.5V12l3 2', stroke: Color(0xFF1C1C1E), sw: 2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const redo = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M5 12.5a7 7 0 1 0 2.3-5.2M5 4.5v4.2h4.2', stroke: Color(0xFF1C1C1E), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const heart = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M12 20.4C5 15.4 3 12.2 3 9a4.6 4.6 0 0 1 9-1.4A4.6 4.6 0 0 1 21 9c0 3.2-2 6.4-9 11.4z', fill: Color(0xFFFFFFFF)),
  ]);

  static const house = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M12 3.2 2.8 11.1h2.4V20h5v-5.4h3.6V20h5v-8.9h2.4z', fill: Color(0xFFFFFFFF)),
  ]);

  static const people = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M5.6 8.5A3.4 3.4 0 1 0 12.4 8.5A3.4 3.4 0 1 0 5.6 8.5Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M2.8 19.2c0-3.6 2.7-5.8 6.2-5.8s6.2 2.2 6.2 5.8z', fill: Color(0xFFFFFFFF)),
    IconPrim('M14.5 9.3A2.7 2.7 0 1 0 19.9 9.3A2.7 2.7 0 1 0 14.5 9.3Z', fill: Color(0xFFFFFFFF)),
    IconPrim('M16.6 13.8c2.8 0 5 1.8 5 5.2h-4.4c0-2-.6-3.6-1.9-4.7.4-.3.8-.5 1.3-.5z', fill: Color(0xFFFFFFFF)),
  ]);

  static const dining = IconSpec(<double>[-18, -30, 36, 60], <IconPrim>[
    IconPrim('M-6 -27H-6A1.6 1.6 0 0 1 -4.4 -25.4V-11.6A1.6 1.6 0 0 1 -6 -10H-6A1.6 1.6 0 0 1 -7.6 -11.6V-25.4A1.6 1.6 0 0 1 -6 -27Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, -9.5, 0]),
    IconPrim('M0 -27H0A1.6 1.6 0 0 1 1.6 -25.4V-11.6A1.6 1.6 0 0 1 0 -10H0A1.6 1.6 0 0 1 -1.6 -11.6V-25.4A1.6 1.6 0 0 1 0 -27Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, -9.5, 0]),
    IconPrim('M6 -27H6A1.6 1.6 0 0 1 7.6 -25.4V-11.6A1.6 1.6 0 0 1 6 -10H6A1.6 1.6 0 0 1 4.4 -11.6V-25.4A1.6 1.6 0 0 1 6 -27Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, -9.5, 0]),
    IconPrim('M-7.6 -15H7.6V-11C7.6 -5.5 2.75 -4.8 2.75 0V26.5A2.75 2.75 0 0 1 -2.75 26.5V0C-2.75 -4.8 -7.6 -5.5 -7.6 -11Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, -9.5, 0]),
    IconPrim('M-8.2 -17A8.2 11 0 1 0 8.2 -17A8.2 11 0 1 0 -8.2 -17Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, 9.5, 0]),
    IconPrim('M-2.4 -8C-1.8 -3 -2.75 -1 -2.75 4V26.5A2.75 2.75 0 0 0 2.75 26.5V4C2.75 -1 1.8 -3 2.4 -8Z', fill: Color(0xFFFFFFFF), m: <double>[1, 0, 0, 1, 9.5, 0]),
  ]);

  static const diningGrad = IconSpec(<double>[-18, -30, 36, 60], <IconPrim>[
    IconPrim('M-6 -27H-6A1.6 1.6 0 0 1 -4.4 -25.4V-11.6A1.6 1.6 0 0 1 -6 -10H-6A1.6 1.6 0 0 1 -7.6 -11.6V-25.4A1.6 1.6 0 0 1 -6 -27Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, -11.5, 0], shadow: _tealShadow),
    IconPrim('M0 -27H0A1.6 1.6 0 0 1 1.6 -25.4V-11.6A1.6 1.6 0 0 1 0 -10H0A1.6 1.6 0 0 1 -1.6 -11.6V-25.4A1.6 1.6 0 0 1 0 -27Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, -11.5, 0], shadow: _tealShadow),
    IconPrim('M6 -27H6A1.6 1.6 0 0 1 7.6 -25.4V-11.6A1.6 1.6 0 0 1 6 -10H6A1.6 1.6 0 0 1 4.4 -11.6V-25.4A1.6 1.6 0 0 1 6 -27Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, -11.5, 0], shadow: _tealShadow),
    IconPrim('M-7.6 -15H7.6V-11C7.6 -5.5 2.75 -4.8 2.75 0V26.5A2.75 2.75 0 0 1 -2.75 26.5V0C-2.75 -4.8 -7.6 -5.5 -7.6 -11Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, -11.5, 0], shadow: _tealShadow),
    IconPrim('M-8.2 -17A8.2 11 0 1 0 8.2 -17A8.2 11 0 1 0 -8.2 -17Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, 11.5, 0], shadow: _tealShadow),
    IconPrim('M-2.4 -8C-1.8 -3 -2.75 -1 -2.75 4V26.5A2.75 2.75 0 0 0 2.75 26.5V4C2.75 -1 1.8 -3 2.4 -8Z', grad: _tealGrad, m: <double>[1, 0, 0, 1, 11.5, 0], shadow: _tealShadow),
  ]);

  static const copy = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M11.3 8.5H17.2A2.8 2.8 0 0 1 20 11.3V17.2A2.8 2.8 0 0 1 17.2 20H11.3A2.8 2.8 0 0 1 8.5 17.2V11.3A2.8 2.8 0 0 1 11.3 8.5Z', stroke: Color(0xFF14201E), sw: 1.9, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M15.5 8.5V6.8A2.8 2.8 0 0 0 12.7 4H6.8A2.8 2.8 0 0 0 4 6.8v5.9a2.8 2.8 0 0 0 2.8 2.8h1.7', stroke: Color(0xFF14201E), sw: 1.9, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const share = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M12 14.6V3.8M8.2 7.4 12 3.6l3.8 3.8', stroke: Color(0xFF14201E), sw: 1.9, cap: StrokeCap.round, join: StrokeJoin.round),
    IconPrim('M8.6 10H7.2A2.2 2.2 0 0 0 5 12.2v6.2A2.2 2.2 0 0 0 7.2 20.6h9.6A2.2 2.2 0 0 0 19 18.4v-6.2A2.2 2.2 0 0 0 16.8 10h-1.4', stroke: Color(0xFF14201E), sw: 1.9, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const clipboard = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M8 5.5H16A3 3 0 0 1 19 8.5V17.5A3 3 0 0 1 16 20.5H8A3 3 0 0 1 5 17.5V8.5A3 3 0 0 1 8 5.5Z', stroke: Color(0xFF14201E), sw: 1.9, cap: StrokeCap.butt, join: StrokeJoin.miter),
    IconPrim('M10.6 3H13.4A2 2 0 0 1 15.4 5V6A2 2 0 0 1 13.4 8H10.6A2 2 0 0 1 8.6 6V5A2 2 0 0 1 10.6 3Z', fill: Color(0xFF14201E)),
  ]);

  static const plus = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M5 12h14M12 5v14', stroke: Color(0xFFAEAEB2), sw: 2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const plusGray = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M5 12h14M12 5v14', stroke: Color(0xFF6C6C70), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const spoonPin = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M7.3 7.6A4.7 6.2 0 1 0 16.7 7.6A4.7 6.2 0 1 0 7.3 7.6Z', fill: Color(0xFFC9D0DA)),
    IconPrim('M10.5 12.6h3L13.1 22.4h-2.2z', fill: Color(0xFFA8B1BE)),
  ]);

  static const chevDown = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M6 9.5l6 6 6-6', stroke: Color(0xFF8E8E93), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.round),
  ]);

  static const close = IconSpec(<double>[0, 0, 24, 24], <IconPrim>[
    IconPrim('M6 6l12 12M18 6L6 18', stroke: Color(0xFFFFFFFF), sw: 2.2, cap: StrokeCap.round, join: StrokeJoin.miter),
  ]);

}
