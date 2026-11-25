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

    // Zemin: vesikalik gibi, ustte acik altta koyu.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(bg, Colors.white, 0.35)!,
            Color.lerp(bg, Colors.black, 0.14)!,
          ],
        ).createShader(Offset.zero & size),
    );

    // --- Olculer ---
    // Portre bir vesikalik gibi kirpiliyor: bas cercevenin buyuk kismini
    // kapliyor, omuzlar alt kenardan giriyor. Onceki surumde kafa cok
    // kucuktu ve resim uzaktan cekilmis gibi duruyordu.
    final cx = w * 0.5;
    final faceCy = h * 0.46;
    final faceW = w * (female ? 0.50 : (male ? 0.55 : 0.52));
    final faceH = h * 0.64;
    final faceRect =
        Rect.fromCenter(center: Offset(cx, faceCy), width: faceW, height: faceH);

    // --- Omuzlar ---
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 1.22),
        width: w * (male ? 1.5 : 1.34),
        height: h * 0.78,
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(cloth, Colors.white, 0.14)!, cloth],
        ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.18)),
    );

    // --- Boyun ---
    final neck = Rect.fromCenter(
      center: Offset(cx, h * 0.86),
      width: faceW * 0.44,
      height: h * 0.26,
    );
    canvas.drawRect(neck, Paint()..color = skin);
    // Cenenin altina dusen golge.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.80),
        width: faceW * 0.56,
        height: h * 0.12,
      ),
      Paint()..color = shade.withValues(alpha: 0.75),
    );

    // --- Sacin arka kutlesi ---
    if (female) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy + faceH * 0.06),
          width: faceW * 1.34,
          height: faceH * 1.3,
        ),
        Paint()..color = hair,
      );
      // Omuzlara inen iki tutam.
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + side * faceW * 0.56, h * 0.82),
            width: faceW * 0.36,
            height: h * 0.46,
          ),
          Paint()..color = hair,
        );
      }
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy - faceH * 0.1),
          width: faceW * (male ? 1.1 : 1.14),
          height: faceH * 0.86,
        ),
        Paint()..color = hair,
      );
    }

    // --- Kulaklar ---
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * faceW * 0.49, faceCy + faceH * 0.04),
          width: faceW * 0.12,
          height: faceH * 0.17,
        ),
        Paint()..color = Color.lerp(skin, shade, 0.5)!,
      );
    }

    // --- Yuz: yumurta bicimi, altta daralan ---
    final face = Path()
      ..moveTo(cx, faceCy - faceH * 0.5)
      ..cubicTo(
        cx + faceW * 0.52, faceCy - faceH * 0.46,
        cx + faceW * 0.52, faceCy + faceH * 0.16,
        cx + faceW * 0.30, faceCy + faceH * 0.40,
      )
      ..cubicTo(
        cx + faceW * 0.18, faceCy + faceH * 0.50,
        cx - faceW * 0.18, faceCy + faceH * 0.50,
        cx - faceW * 0.30, faceCy + faceH * 0.40,
      )
      ..cubicTo(
        cx - faceW * 0.52, faceCy + faceH * 0.16,
        cx - faceW * 0.52, faceCy - faceH * 0.46,
        cx, faceCy - faceH * 0.5,
      )
      ..close();
    canvas.drawPath(
      face,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Color.lerp(skin, Colors.white, 0.20)!, skin, shade],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(faceRect),
    );

    canvas.save();
    canvas.clipPath(face);

    // Elmacik kemigi ve sakak golgeleri: yuzu duz bir yuzey olmaktan
    // cikaran sey bunlar.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + side * faceW * 0.40, faceCy + faceH * 0.05),
          width: faceW * 0.3,
          height: faceH * 0.44,
        ),
        Paint()..color = shade.withValues(alpha: 0.28),
      );
    }

    if (beard) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy + faceH * 0.42),
          width: faceW * 0.9,
          height: faceH * 0.5,
        ),
        Paint()..color = hair.withValues(alpha: 0.55),
      );
      // Bıyık.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, faceCy + faceH * 0.21),
          width: faceW * 0.4,
          height: faceH * 0.07,
        ),
        Paint()..color = hair.withValues(alpha: 0.7),
      );
    }

    // --- Sac cizgisi: yarim daire degil, alinda hafif V yapan bir egri ---
    final hairline = Path()
      ..moveTo(cx - faceW * 0.5, faceCy - faceH * 0.22)
      ..cubicTo(
        cx - faceW * 0.46, faceCy - faceH * 0.46,
        cx - faceW * 0.20, faceCy - faceH * 0.56,
        cx, faceCy - faceH * (female ? 0.50 : 0.53),
      )
      ..cubicTo(
        cx + faceW * 0.20, faceCy - faceH * 0.56,
        cx + faceW * 0.46, faceCy - faceH * 0.46,
        cx + faceW * 0.5, faceCy - faceH * 0.22,
      )
      ..lineTo(cx + faceW * 0.5, faceCy - faceH * 0.6)
      ..lineTo(cx - faceW * 0.5, faceCy - faceH * 0.6)
      ..close();
    canvas.drawPath(hairline, Paint()..color = hair);

    if (male && (seed ~/ 37).isEven) {
      // Yandan ayrim: sacin bir tarafi alna dogru iner.
      canvas.drawPath(
        Path()
          ..moveTo(cx - faceW * 0.5, faceCy - faceH * 0.3)
          ..quadraticBezierTo(
            cx - faceW * 0.1, faceCy - faceH * 0.42,
            cx + faceW * 0.34, faceCy - faceH * 0.24,
          )
          ..lineTo(cx + faceW * 0.5, faceCy - faceH * 0.6)
          ..lineTo(cx - faceW * 0.5, faceCy - faceH * 0.6)
          ..close(),
        Paint()..color = hair,
      );
    }
    if (female) {
      // Yuzun iki yanina inen sac kenarlari.
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + side * faceW * 0.52, faceCy - faceH * 0.05),
            width: faceW * 0.3,
            height: faceH * 0.8,
          ),
          Paint()..color = hair,
        );
      }
    }

    canvas.restore();

    // Sactaki isik seridi.
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, faceCy - faceH * 0.34),
        width: faceW * 0.78,
        height: faceH * 0.34,
      ),
      math.pi * 1.18,
      math.pi * 0.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = faceW * 0.055
        ..strokeCap = StrokeCap.round
        ..color = hairLight.withValues(alpha: 0.6),
    );

    // --- Kaslar ---
    for (final side in [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(cx + side * faceW * 0.21, faceCy - faceH * 0.1),
          width: faceW * 0.3,
          height: faceH * 0.12,
        ),
        math.pi * 1.06,
        math.pi * 0.88,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceW * (female ? 0.028 : 0.042)
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(hair, Colors.black, 0.1)!,
      );
    }

    // --- Gozler: badem bicimi ---
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(cx + side * faceW * 0.21, faceCy - faceH * 0.01);
      final eyeW = faceW * 0.21;
      final eyeH = faceH * 0.062;

      final socket = Path()
        ..moveTo(eye.dx - eyeW / 2, eye.dy)
        ..quadraticBezierTo(eye.dx, eye.dy - eyeH, eye.dx + eyeW / 2, eye.dy)
        ..quadraticBezierTo(eye.dx, eye.dy + eyeH * 0.85, eye.dx - eyeW / 2, eye.dy)
        ..close();
      canvas.drawPath(socket, Paint()..color = const Color(0xFFFAFAFA));

      canvas.save();
      canvas.clipPath(socket);
      canvas.drawCircle(eye, eyeH * 0.78, Paint()..color = iris);
      canvas.drawCircle(
          eye, eyeH * 0.34, Paint()..color = const Color(0xFF14100C));
      canvas.drawCircle(
        eye.translate(-eyeH * 0.3, -eyeH * 0.3),
        eyeH * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      canvas.restore();

      // Ust kapak cizgisi ve kirpik hissi.
      canvas.drawPath(
        Path()
          ..moveTo(eye.dx - eyeW / 2, eye.dy)
          ..quadraticBezierTo(eye.dx, eye.dy - eyeH, eye.dx + eyeW / 2, eye.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceW * (female ? 0.028 : 0.022)
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2A1D14),
      );
    }

    // --- Burun: koprunun golgesi ve kanat ---
    canvas.drawPath(
      Path()
        ..moveTo(cx - faceW * 0.015, faceCy + faceH * 0.02)
        ..lineTo(cx - faceW * 0.045, faceCy + faceH * 0.13)
        ..quadraticBezierTo(
          cx, faceCy + faceH * 0.165,
          cx + faceW * 0.045, faceCy + faceH * 0.13,
        ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = faceW * 0.022
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = shade,
    );

    // --- Agiz ---
    final mouthY = faceCy + faceH * 0.26;
    if (female) {
      final lip = Paint()..color = const Color(0xFFB4565A);
      canvas.drawPath(
        Path()
          ..moveTo(cx - faceW * 0.12, mouthY)
          ..quadraticBezierTo(
              cx - faceW * 0.06, mouthY - faceH * 0.028, cx, mouthY - faceH * 0.004)
          ..quadraticBezierTo(
              cx + faceW * 0.06, mouthY - faceH * 0.028, cx + faceW * 0.12, mouthY)
          ..quadraticBezierTo(cx, mouthY + faceH * 0.05, cx - faceW * 0.12, mouthY)
          ..close(),
        lip,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(cx - faceW * 0.1, mouthY)
          ..quadraticBezierTo(cx, mouthY + faceH * 0.035, cx + faceW * 0.1, mouthY),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = faceW * 0.028
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8A4840),
      );
    }

    // --- Yanak kizarikligi ---
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + side * faceW * 0.26, faceCy + faceH * 0.13),
        faceW * 0.1,
        Paint()..color = blush.withValues(alpha: 0.26),
      );
    }

    // Alt kenarda hafif bir karartma: fotograf vinyeti gibi, portreyi
    // cerceve icine oturtuyor.
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.7, w, h * 0.3),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.18),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.7, w, h * 0.3)),
    );
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.gender != gender;
}
