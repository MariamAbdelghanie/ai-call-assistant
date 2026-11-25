import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Arayanin yuvarlak karakter resmi.
///
/// Referans tasarimda her satirda bir kisi fotografi var. Gercek fotograf
/// koyamayiz: arayanin fotografini bilmiyoruz, stok fotograf da hem telifli
/// hem de olmayan bir kisiyi gercekmis gibi gosterir. Bunun yerine ada gore
/// cizilen bir portre kullaniyorum. Ayni ad her zaman ayni yuzu verdigi icin
/// liste tanidik geliyor, hicbir veri uydurulmus olmuyor.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.statusColor,
  });

  final String name;
  final double size;

  /// Saga alta konan kucuk durum noktasi (acil, geri donus bekliyor...).
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final seed = _seedOf(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _PortraitPainter(seed: seed)),
            ),
          ),
          if (statusColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.glass, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Addan sabit bir sayi uretir; ayni ad hep ayni yuzu alir.
  static int _seedOf(String value) {
    var hash = 7;
    for (final unit in value.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({required this.seed});

  final int seed;

  // Zemin tonlari: paletin disina cikmayan, birbirinden ayrilan renkler.
  static const _backgrounds = <Color>[
    Color(0xFFFFE3D1),
    Color(0xFFE2E7F5),
    Color(0xFFD8EFE4),
    Color(0xFFFBE2E4),
    Color(0xFFEDE6F6),
    Color(0xFFFFF0CC),
  ];

  static const _skins = <Color>[
    Color(0xFFF2C9A8),
    Color(0xFFE0AC7E),
    Color(0xFFC68A5E),
    Color(0xFF9C6440),
  ];

  static const _hairs = <Color>[
    Color(0xFF2B2118),
    Color(0xFF4A3524),
    Color(0xFF7A5230),
    Color(0xFF1B2A4A),
    Color(0xFF5B5B61),
  ];

  static const _clothes = <Color>[
    AppPalette.indigo,
    Color(0xFF2F6F5E),
    Color(0xFF8A4B2A),
    Color(0xFF4A4A72),
    Color(0xFFB45309),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bg = _backgrounds[seed % _backgrounds.length];
    final skin = _skins[(seed ~/ 7) % _skins.length];
    final hair = _hairs[(seed ~/ 13) % _hairs.length];
    final cloth = _clothes[(seed ~/ 17) % _clothes.length];
    // Uzun sac / kisa sac: iki farkli silüet, ada gore secilir.
    final longHair = (seed ~/ 23).isEven;

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    final headCenter = Offset(w * 0.5, h * 0.44);
    final headRadius = w * 0.21;

    // Omuzlar: daire icine oturan genis bir kemer.
    final shoulders = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 1.02),
          width: w * 0.92,
          height: h * 0.72,
        ),
      );
    canvas.drawPath(shoulders, Paint()..color = cloth);

    // Boyun.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.66),
          width: w * 0.18,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.07),
      ),
      Paint()..color = skin,
    );

    if (longHair) {
      // Uzun sac once cizilir: yuzun arkasinda kalir.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: headRadius * 2.65,
          height: headRadius * 2.9,
        ),
        Paint()..color = hair,
      );
    }

    canvas.drawCircle(headCenter, headRadius, Paint()..color = skin);

    // Sac: basin ust yarisini orten bir yay.
    final capRect = Rect.fromCircle(
      center: headCenter,
      radius: headRadius * (longHair ? 1.06 : 1.03),
    );
    canvas.drawArc(
      capRect,
      math.pi * 1.04,
      math.pi * 0.92,
      true,
      Paint()..color = hair,
    );

    // Gozler ve agiz: cok kucuk, yuz ifadesi notr kalsin.
    final eye = Paint()..color = const Color(0xFF2B2118);
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius * 0.36, headCenter.dy + headRadius * 0.06),
      headRadius * 0.095,
      eye,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius * 0.36, headCenter.dy + headRadius * 0.06),
      headRadius * 0.095,
      eye,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.42),
        width: headRadius * 0.62,
        height: headRadius * 0.42,
      ),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.1
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF8A5A42),
    );
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) => oldDelegate.seed != seed;
}
