import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Arayanin yuvarlak portresi.
///
/// Gercek fotograf kullanmiyoruz: arayanin yuzunu bilmiyoruz ve stok bir
/// fotograf, olmayan bir kisiyi arayanmis gibi gosterir. Bunun yerine
/// portre adin kendisinden ciziliyor; ayni ad her zaman ayni yuzu verdigi
/// icin liste tanidik geliyor, hicbir veri uydurulmus olmuyor.
///
/// Ad tanindiginda kadin/erkek portresi secilir; taninmayan adlarda
/// cinsiyete isaret etmeyen notr bir portre cizilir.
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

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _PortraitPainter(
                  seed: _seedOf(name),
                  gender: _genderOf(name),
                ),
              ),
            ),
          ),
          if (statusColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
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

  /// Ilk ada bakarak cinsiyet tahmini. Liste disindaki adlar notr kalir;
  /// yanlis tahmin etmektense tahmin etmemek daha iyi.
  static _Gender _genderOf(String value) {
    final first = value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .split(RegExp(r'\s+'))
        .first;
    if (first.isEmpty) return _Gender.neutral;
    if (_female.contains(first)) return _Gender.female;
    if (_male.contains(first)) return _Gender.male;
    return _Gender.neutral;
  }

  static const _female = <String>{
    // Turkce
    'ayse', 'ayşe', 'fatma', 'emine', 'hatice', 'zeynep', 'elif', 'merve',
    'büsra', 'büşra', 'seda', 'esra', 'özlem', 'ozlem', 'selin', 'ece',
    'derya', 'melike', 'melis', 'ebru', 'burcu', 'gamze', 'gizem', 'irem',
    'nur', 'nurcan', 'sevgi', 'sevil', 'şeyma', 'seyma', 'tugce', 'tuğçe',
    'yasemin', 'zehra', 'dilek', 'duygu', 'pinar', 'pınar', 'sema', 'sibel',
    'aylin', 'aysel', 'bahar', 'ceren', 'damla', 'defne', 'eda', 'funda',
    'hande', 'ilayda', 'kübra', 'kubra', 'lale', 'meltem', 'nazli', 'nazlı',
    'nilay', 'nilüfer', 'nilufer', 'rabia', 'simge', 'sila', 'şila', 'tuba',
    'ulku', 'ülkü', 'yagmur', 'yağmur', 'zelis', 'beyza', 'meryem',
    // Arapca
    'mariam', 'maryam', 'مريم', 'فاطمة', 'عائشة', 'سارة', 'منى', 'ليلى',
    'نور', 'هدى', 'رنا', 'دينا', 'ريم', 'سلمى', 'ياسمين', 'زينب', 'أمل',
    'اسماء', 'أسماء', 'هبة', 'شيماء', 'نجلاء', 'انعام', 'إيناس', 'ايناس',
    'sara', 'salma', 'dina', 'rana', 'hoda', 'huda', 'laila', 'layla',
    'amal', 'enas', 'esraa', 'nour', 'noura', 'reem',
    // Diger
    'laura', 'anna', 'maria', 'julia', 'sophie', 'emma', 'elena', 'clara',
  };

  static const _male = <String>{
    // Turkce
    'mehmet', 'ahmet', 'mustafa', 'ali', 'hüseyin', 'huseyin', 'hasan',
    'ibrahim', 'ismail', 'osman', 'yusuf', 'murat', 'ömer', 'omer', 'ramazan',
    'kadir', 'burak', 'emre', 'serkan', 'hakan', 'fatih', 'oguz', 'oğuz',
    'kemal', 'kerem', 'onur', 'tolga', 'volkan', 'yasin', 'bilal', 'cem',
    'can', 'deniz', 'eren', 'ercan', 'ferhat', 'gökhan', 'gokhan', 'halil',
    'levent', 'metin', 'muhammed', 'okan', 'orhan', 'sinan', 'suleyman',
    'süleyman', 'tarik', 'tarık', 'ufuk', 'umut', 'yavuz', 'baris', 'barış',
    'furkan', 'enes', 'berk', 'arda', 'taha', 'selim', 'batuhan',
    // Arapca
    'محمد', 'أحمد', 'احمد', 'علي', 'عمر', 'يوسف', 'خالد', 'حسن', 'حسين',
    'مصطفى', 'إبراهيم', 'ابراهيم', 'طارق', 'سامي', 'كريم', 'زياد', 'رامي',
    'ahmed', 'mohamed', 'mohammed', 'khaled', 'karim', 'omar', 'tarek',
    'sami', 'ziad', 'rami', 'hassan', 'hussein',
    // Diger
    'thomas', 'michael', 'david', 'john', 'daniel', 'peter', 'lucas',
  };
}

enum _Gender { female, male, neutral }

class _PortraitPainter extends CustomPainter {
  _PortraitPainter({required this.seed, required this.gender});

  final int seed;
  final _Gender gender;

  static const _backgrounds = <Color>[
    Color(0xFFE7EBF7),
    Color(0xFFFFE6D6),
    Color(0xFFDCEFE6),
    Color(0xFFF7E3E8),
    Color(0xFFEDE7F7),
    Color(0xFFFFF1D4),
  ];

  /// Ten: (ana ton, golge, kizariklik). Her ten icin ayri golge, cunku
  /// tek bir gri golge koyu tende kirli gorunuyor.
  static const _skins = <(Color, Color, Color)>[
    (Color(0xFFF7D7BE), Color(0xFFE2B394), Color(0xFFEBB6A0)),
    (Color(0xFFEEC09C), Color(0xFFD29C74), Color(0xFFE0A389)),
    (Color(0xFFD3A074), Color(0xFFB07C50), Color(0xFFC08763)),
    (Color(0xFFA9774D), Color(0xFF8A5B34), Color(0xFF9A6540)),
    (Color(0xFF7A5133), Color(0xFF5C3A22), Color(0xFF6D452B)),
  ];

  static const _hairs = <(Color, Color)>[
    (Color(0xFF241A13), Color(0xFF3E2D20)),
    (Color(0xFF3B291B), Color(0xFF5A4129)),
    (Color(0xFF6B4423), Color(0xFF8F6134)),
    (Color(0xFF1A2742), Color(0xFF2B3C5E)),
    (Color(0xFF4F4F55), Color(0xFF74747C)),
  ];

  static const _clothes = <Color>[
    AppPalette.indigo,
    Color(0xFF2F6F5E),
    Color(0xFF8A4B2A),
    Color(0xFF474772),
    Color(0xFF9A3412),
    Color(0xFF2F4858),
  ];

  static const _irises = <Color>[
    Color(0xFF4A3524),
    Color(0xFF2F4F4F),
    Color(0xFF2B4C7E),
    Color(0xFF50603A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bg = _backgrounds[seed % _backgrounds.length];
    final (skin, shade, blush) = _skins[(seed ~/ 7) % _skins.length];
    final (hair, hairLight) = _hairs[(seed ~/ 13) % _hairs.length];
    final cloth = _clothes[(seed ~/ 17) % _clothes.length];
    final iris = _irises[(seed ~/ 31) % _irises.length];

    final female = gender == _Gender.female;
    final male = gender == _Gender.male;
    final beard = male && (seed ~/ 29) % 3 == 0;

    // Zemin: hafif dikey gecis, derinlik hissi icin.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg, Color.lerp(bg, Colors.black, 0.12)!],
        ).createShader(Offset.zero & size),
    );

    final cx = w * 0.5;
    final faceCy = h * 0.42;
    // Kadin yuzu biraz daha dar, erkek yuzu biraz daha genis: silueti
    // sactan bagimsiz olarak da ayiran sey bu.
    final faceW = w * (female ? 0.38 : (male ? 0.43 : 0.405));
    final faceH = h * 0.47;
    final faceRect =
        Rect.fromCenter(center: Offset(cx, faceCy), width: faceW, height: faceH);

    // --- Omuzlar ---
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 1.06),
        width: w * (male ? 1.04 : 0.94),
        height: h * 0.74,
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(cloth, Colors.white, 0.16)!, cloth],
        ).createShader(Rect.fromLTWH(0, h * 0.66, w, h * 0.34)),
    );

    // Yaka
    canvas.drawPath(
      Path()
        ..moveTo(cx, h * 0.95)
        ..lineTo(cx - w * 0.14, h * 0.74)
        ..lineTo(cx - w * 0.06, h * 0.71)
        ..lineTo(cx, h * 0.81)
        ..lineTo(cx + w * 0.06, h * 0.71)
        ..lineTo(cx + w * 0.14, h * 0.74)
        ..close(),
      Paint()..color = Color.lerp(cloth, Colors.white, 0.24)!,
    );

    // --- Boyun ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.645),
          width: faceW * 0.46,
          height: h * 0.2,
        ),
        Radius.circular(w * 0.07),
      ),
      Paint()..color = shade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.625),
          width: faceW * 0.42,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.07),
      ),
      Paint()..color = skin,
    );

    // --- Sacin arka kutlesi ---
    if (female) {
      // Uzun sac: omuzlara inen iki kutle.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.52),
          width: faceW * 1.46,
          height: faceH * 1.42,
        ),
        Paint()..color = hair,
      );
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + side * faceW * 0.56, h * 0.64),
            width: faceW * 0.42,
            height: h * 0.42,
          ),
          Paint()..color = hair,
        );
      }
    } else if (male) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy - faceH * 0.06),
          width: faceW * 1.14,
          height: faceH * 0.92,
        ),
        Paint()..color = hair,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy - faceH * 0.04),
          width: faceW * 1.2,
          height: faceH * 1.0,
        ),
        Paint()..color = hair,
      );
    }

    // --- Kulaklar ---
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * faceW * 0.5, faceCy + faceH * 0.06),
          width: faceW * 0.15,
          height: faceH * 0.2,
        ),
        Paint()..color = shade,
      );
    }

    // --- Yuz ---
    canvas.drawOval(
      faceRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [Color.lerp(skin, Colors.white, 0.18)!, skin, shade],
          stops: const [0.0, 0.58, 1.0],
        ).createShader(faceRect),
    );

    // Cene golgesi: yuzun alt kenarini yumusatir.
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, faceCy + faceH * 0.56),
        width: faceW * 0.92,
        height: faceH * 0.4,
      ),
      Paint()..color = shade.withValues(alpha: 0.35),
    );
    if (beard) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy + faceH * 0.44),
          width: faceW * 0.86,
          height: faceH * 0.56,
        ),
        Paint()..color = hair.withValues(alpha: 0.62),
      );
    }
    canvas.restore();

    // --- On sac ---
    final capRect = Rect.fromCenter(
      center: Offset(cx, faceCy - faceH * 0.1),
      width: faceW * (female ? 1.14 : 1.08),
      height: faceH * (female ? 0.86 : 0.78),
    );
    canvas.drawArc(capRect, math.pi * 1.0, math.pi, true, Paint()..color = hair);
    if (male && (seed ~/ 37).isEven) {
      // Yandan ayrilmis sac: duz kavis herkeste ayni gorunuyordu.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + faceW * 0.16, faceCy - faceH * 0.3),
          width: faceW * 0.7,
          height: faceH * 0.3,
        ),
        Paint()..color = hair,
      );
    }
    canvas.drawArc(
      capRect.deflate(faceW * 0.07),
      math.pi * 1.16,
      math.pi * 0.36,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = faceW * 0.07
        ..strokeCap = StrokeCap.round
        ..color = hairLight.withValues(alpha: 0.7),
    );

    // --- Kaslar ---
    final brow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceW * (female ? 0.035 : 0.05)
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(hair, Colors.black, 0.12)!;
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx + side * faceW * 0.19, faceCy - faceH * 0.12),
          width: faceW * 0.28,
          height: faceH * 0.14,
        ),
        math.pi * 1.08,
        math.pi * 0.84,
        false,
        brow,
      );
    }

    // --- Gozler ---
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(cx + side * faceW * 0.19, faceCy + faceH * 0.02);
      final eyeW = faceW * 0.22;
      final eyeH = faceH * 0.085;
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: eyeW, height: eyeH),
        Paint()..color = const Color(0xFFFCFCFC),
      );
      canvas.drawCircle(eye, eyeH * 0.52, Paint()..color = iris);
      canvas.drawCircle(eye, eyeH * 0.24, Paint()..color = const Color(0xFF16100C));
      canvas.drawCircle(
        eye.translate(-eyeH * 0.22, -eyeH * 0.22),
        eyeH * 0.15,
        Paint()..color = Colors.white,
      );
      canvas.drawArc(
        Rect.fromCenter(center: eye, width: eyeW * 1.04, height: eyeH * 1.1),
        math.pi * 1.04,
        math.pi * 0.92,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceW * (female ? 0.035 : 0.028)
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF32241A),
      );
    }

    // --- Burun ---
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, faceCy + faceH * 0.17),
        width: faceW * 0.14,
        height: faceH * 0.12,
      ),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = faceW * 0.03
        ..strokeCap = StrokeCap.round
        ..color = shade,
    );

    // --- Agiz ---
    if (female) {
      // Dudak: iki yay, ustte ince altta dolgun.
      final mouth = Offset(cx, faceCy + faceH * 0.3);
      final lip = Paint()..color = const Color(0xFFB4565A);
      canvas.drawOval(
        Rect.fromCenter(
          center: mouth.translate(0, faceH * 0.012),
          width: faceW * 0.26,
          height: faceH * 0.062,
        ),
        lip,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: mouth.translate(0, -faceH * 0.018),
          width: faceW * 0.22,
          height: faceH * 0.04,
        ),
        Paint()..color = const Color(0xFFC4676B),
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx, faceCy + faceH * 0.28),
          width: faceW * 0.26,
          height: faceH * 0.1,
        ),
        0.22,
        math.pi - 0.44,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceW * 0.035
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8F4A42),
      );
    }

    // --- Yanak kizarikligi: yuze canlilik veren son dokunus ---
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + side * faceW * 0.3, faceCy + faceH * 0.2),
        faceW * 0.1,
        Paint()..color = blush.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.gender != gender;
}
