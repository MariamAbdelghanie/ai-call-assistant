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

  // Ten tonlari acik-koyu siralanir; her biri icin ayri bir golge rengi
  // var, cunku tek bir gri golge koyu tende kirli gorunuyordu.
  static const _skins = <(Color, Color)>[
    (Color(0xFFF6D5BC), Color(0xFFE0B092)),
    (Color(0xFFEDBE99), Color(0xFFD09B72)),
    (Color(0xFFCE9A6E), Color(0xFFAE7A50)),
    (Color(0xFFA2714A), Color(0xFF855631)),
    (Color(0xFF6F4A2F), Color(0xFF55361F)),
  ];

  static const _hairs = <(Color, Color)>[
    (Color(0xFF2B2118), Color(0xFF433225)),
    (Color(0xFF4A3524), Color(0xFF6A4D33)),
    (Color(0xFF8A5A2B), Color(0xFFB07C45)),
    (Color(0xFF1B2A4A), Color(0xFF2C3F66)),
    (Color(0xFF5B5B61), Color(0xFF7D7D85)),
  ];

  static const _clothes = <Color>[
    AppPalette.indigo,
    Color(0xFF2F6F5E),
    Color(0xFF8A4B2A),
    Color(0xFF4A4A72),
    Color(0xFF9A3412),
    Color(0xFF334155),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bg = _backgrounds[seed % _backgrounds.length];
    final (skin, skinShade) = _skins[(seed ~/ 7) % _skins.length];
    final (hair, hairLight) = _hairs[(seed ~/ 13) % _hairs.length];
    final cloth = _clothes[(seed ~/ 17) % _clothes.length];
    final longHair = (seed ~/ 23).isEven;
    final hasBeard = !longHair && (seed ~/ 29) % 3 == 0;

    // Zemin: duz renk yerine hafif bir dikey gecis; fotograf gibi
    // derinlik veren en ucuz numara.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg, Color.lerp(bg, Colors.black, 0.10)!],
        ).createShader(Offset.zero & size),
    );

    final headCenter = Offset(w * 0.5, h * 0.43);
    final headRadius = w * 0.205;

    // --- Govde ve yaka ---
    canvas.drawPath(
      Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 1.04),
            width: w * 0.96,
            height: h * 0.74,
          ),
        ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(cloth, Colors.white, 0.12)!,
            cloth,
          ],
        ).createShader(
          Rect.fromLTWH(0, h * 0.68, w, h * 0.32),
        ),
    );

    // Yaka: omuzlarin ortasinda ters bir V. Giysiyi tisortten gomlege
    // cevirip portreyi daha "insan" yapan ayrinti.
    final collar = Path()
      ..moveTo(w * 0.5, h * 0.92)
      ..lineTo(w * 0.36, h * 0.74)
      ..lineTo(w * 0.44, h * 0.71)
      ..lineTo(w * 0.5, h * 0.80)
      ..lineTo(w * 0.56, h * 0.71)
      ..lineTo(w * 0.64, h * 0.74)
      ..close();
    canvas.drawPath(
      collar,
      Paint()..color = Color.lerp(cloth, Colors.white, 0.26)!,
    );

    // --- Boyun ve altindaki golge ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.645),
          width: w * 0.2,
          height: h * 0.2,
        ),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = skinShade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.63),
          width: w * 0.19,
          height: h * 0.17,
        ),
        Radius.circular(w * 0.08),
      ),
      Paint()..color = skin,
    );

    // --- Sac: once arka kutle ---
    if (longHair) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.52),
          width: headRadius * 2.75,
          height: headRadius * 3.0,
        ),
        Paint()..color = hair,
      );
    }

    // --- Yuz ---
    canvas.drawOval(
      Rect.fromCenter(
        center: headCenter,
        width: headRadius * 1.86,
        height: headRadius * 2.18,
      ),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(skin, Colors.white, 0.16)!, skin, skinShade],
          stops: const [0.0, 0.62, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: headCenter,
            width: headRadius * 1.86,
            height: headRadius * 2.18,
          ),
        ),
    );

    // Kulaklar.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            headCenter.dx + side * headRadius * 0.93,
            headCenter.dy + headRadius * 0.12,
          ),
          width: headRadius * 0.3,
          height: headRadius * 0.46,
        ),
        Paint()..color = skinShade,
      );
    }

    // --- Sac: on kutle ---
    final capRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy - headRadius * 0.12),
      width: headRadius * 1.96,
      height: headRadius * 1.9,
    );
    canvas.drawArc(capRect, math.pi * 1.02, math.pi * 0.96, true,
        Paint()..color = hair);
    // Sacin uzerinde ince bir isik seridi.
    canvas.drawArc(
      capRect.deflate(headRadius * 0.12),
      math.pi * 1.18,
      math.pi * 0.34,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.12
        ..strokeCap = StrokeCap.round
        ..color = hairLight.withValues(alpha: 0.75),
    );

    // --- Kaslar ---
    final brow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = headRadius * 0.095
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(hair, Colors.black, 0.1)!;
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(
            headCenter.dx + side * headRadius * 0.37,
            headCenter.dy - headRadius * 0.16,
          ),
          width: headRadius * 0.52,
          height: headRadius * 0.34,
        ),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        brow,
      );
    }

    // --- Gozler: ak, iris, bebek ve ustunde kucuk bir parlama ---
    const irises = <Color>[
      Color(0xFF4A3524),
      Color(0xFF2F4F4F),
      Color(0xFF2B4C7E),
      Color(0xFF50603A),
    ];
    final iris = irises[(seed ~/ 31) % irises.length];
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(
        headCenter.dx + side * headRadius * 0.36,
        headCenter.dy + headRadius * 0.04,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: eye,
          width: headRadius * 0.42,
          height: headRadius * 0.27,
        ),
        Paint()..color = const Color(0xFFFBFBFB),
      );
      canvas.drawCircle(eye, headRadius * 0.115, Paint()..color = iris);
      canvas.drawCircle(
        eye,
        headRadius * 0.05,
        Paint()..color = const Color(0xFF17120E),
      );
      canvas.drawCircle(
        eye.translate(-headRadius * 0.045, -headRadius * 0.045),
        headRadius * 0.032,
        Paint()..color = Colors.white,
      );
      // Ust goz kapagi cizgisi.
      canvas.drawArc(
        Rect.fromCenter(
          center: eye,
          width: headRadius * 0.44,
          height: headRadius * 0.3,
        ),
        math.pi * 1.05,
        math.pi * 0.9,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = headRadius * 0.055
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF3A2A1E),
      );
    }

    // --- Burun: tek bir golge cizgisi ---
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.34),
        width: headRadius * 0.3,
        height: headRadius * 0.3,
      ),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.07
        ..strokeCap = StrokeCap.round
        ..color = skinShade,
    );

    if (hasBeard) {
      // Sakal: cene cevresinde yumusak bir golge.
      canvas.save();
      canvas.clipPath(
        Path()
          ..addOval(
            Rect.fromCenter(
              center: headCenter,
              width: headRadius * 1.86,
              height: headRadius * 2.18,
            ),
          ),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.95),
          width: headRadius * 1.5,
          height: headRadius * 1.1,
        ),
        Paint()..color = hair.withValues(alpha: 0.55),
      );
      canvas.restore();
    }

    // --- Agiz ---
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.6),
        width: headRadius * 0.6,
        height: headRadius * 0.4,
      ),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = headRadius * 0.1
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9C5548),
    );
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) => oldDelegate.seed != seed;
}
