import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Asistanin durumu. Robot bu duruma gore renk degistirir ve hareket eder.
enum RobotMood { idle, connecting, listening, speaking, ended }

/// Uygulamanin kendi robot karakteri.
///
/// Parlak govde, pudra yanaklar ve buzlu cam vizor ile cizilir. Konusurken
/// agzi dalgalanir, dinlerken nefes alir, arada goz kirpar ve surekli hafifce
/// suzulur. Hareketler "azaltilmis hareket" ayarina saygi duyar.
class AssistantRobot extends StatefulWidget {
  const AssistantRobot({super.key, required this.mood, this.size = 220});

  final RobotMood mood;
  final double size;

  @override
  State<AssistantRobot> createState() => _AssistantRobotState();
}

class _AssistantRobotState extends State<AssistantRobot>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );

  double _sinceBlink = 0;

  @override
  void initState() {
    super.initState();
    _loop.addListener(_tick);
  }

  void _tick() {
    _sinceBlink += 0.016;
    if (_sinceBlink > 3.2) {
      _sinceBlink = 0;
      if (mounted && !_blink.isAnimating) {
        _blink.forward().then((_) {
          if (mounted) _blink.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _loop.removeListener(_tick);
    _loop.dispose();
    _blink.dispose();
    super.dispose();
  }

  /// Govde hep mavi kalir; yalnizca vizordeki isik rengi duruma gore degisir.
  /// Boylece karakter kimligini korur, durum ise tek bakista okunur.
  ({Color body, Color aura, Color accent}) _palette() {
    const base = AppPalette.brand;
    return switch (widget.mood) {
      RobotMood.idle => (
          body: base,
          aura: AppPalette.brandLight,
          accent: Color(0xFF9EDBFF),
        ),
      RobotMood.connecting => (
          body: base,
          aura: AppPalette.brandLight,
          accent: AppPalette.pending,
        ),
      RobotMood.listening => (
          body: base,
          aura: AppPalette.brandLight,
          accent: AppPalette.success,
        ),
      RobotMood.speaking => (
          body: base,
          aura: AppPalette.brandLight,
          accent: Color(0xFF9EDBFF),
        ),
      RobotMood.ended => (
          body: Color(0xFF8C9BAC),
          aura: Color(0xFF8C9BAC),
          accent: Color(0xFFCBD5E0),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final colors = _palette();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _blink]),
        builder: (context, _) => CustomPaint(
          painter: _RobotPainter(
            t: reduceMotion ? 0.0 : _loop.value,
            mood: widget.mood,
            body: colors.body,
            aura: colors.aura,
            accent: colors.accent,
            blink: _blink.value,
            isDark: context.tokens.isDark,
            still: reduceMotion,
          ),
        ),
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({
    required this.t,
    required this.mood,
    required this.body,
    required this.aura,
    required this.accent,
    required this.blink,
    required this.isDark,
    required this.still,
  });

  final double t;
  final RobotMood mood;
  final Color body;
  final Color aura;
  final Color accent;
  final double blink;
  final bool isDark;
  final bool still;

  bool get _active =>
      mood == RobotMood.listening ||
      mood == RobotMood.speaking ||
      mood == RobotMood.connecting;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phase = still ? 0.0 : t;
    final float =
        math.sin(phase * 2 * math.pi) * (_active ? h * 0.018 : h * 0.009);

    // Govde merkezi biraz asagida; kafa ustte kalsin diye ayri yurutuluyor.
    final headC = Offset(w / 2, h * 0.42 + float);
    final headR = w * 0.235;

    _glow(canvas, headC, w, phase);
    _groundShadow(canvas, w, h);
    _torso(canvas, w, h, float);
    _hands(canvas, w, h, float, phase);
    _ears(canvas, headC, headR);
    _head(canvas, headC, headR);
    _visor(canvas, headC, headR, phase);
    _halo(canvas, headC, headR, phase);
  }

  void _glow(Canvas canvas, Offset c, double w, double phase) {
    canvas.drawCircle(
      c,
      w * 0.34,
      Paint()
        ..color = aura.withValues(alpha: isDark ? 0.30 : 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    if (!still &&
        (mood == RobotMood.speaking || mood == RobotMood.connecting)) {
      for (var i = 0; i < 3; i++) {
        final p = (phase * 1.6 + i / 3) % 1.0;
        canvas.drawCircle(
          c,
          w * (0.26 + p * 0.18),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = aura.withValues(alpha: (1 - p) * 0.28),
        );
      }
    }
  }

  void _groundShadow(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.90),
        width: w * 0.38,
        height: h * 0.040,
      ),
      Paint()
        ..color =
            const Color(0xFF0B0518).withValues(alpha: isDark ? 0.40 : 0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
    );
  }

  /// Omuz hatti yuvarlak, asagi dogru hafifce genisleyen bir govde.
  void _torso(Canvas canvas, double w, double h, double float) {
    final top = h * 0.60 + float * 0.5;
    final rect = Rect.fromLTRB(w * 0.30, top, w * 0.70, h * 0.88);
    final shape = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(w * 0.19),
      topRight: Radius.circular(w * 0.19),
      bottomLeft: Radius.circular(w * 0.11),
      bottomRight: Radius.circular(w * 0.11),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(body, Colors.white, 0.30)!,
            Color.lerp(body, const Color(0xFF14091F), 0.45)!,
          ],
        ).createShader(rect),
    );
    // Gogus isigi: durum rengini govdede de tekrarlar.
    final chest = Offset(w / 2, top + h * 0.085);
    canvas.drawCircle(
      chest,
      w * 0.050,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawCircle(chest, w * 0.030, Paint()..color = accent);
    canvas.drawCircle(
      chest,
      w * 0.030,
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  /// Yanlarda serbestce suzulen iki yuvarlak el.
  void _hands(Canvas canvas, double w, double h, double float, double phase) {
    final swing = still ? 0.0 : math.sin(phase * 2 * math.pi + 1.1) * h * 0.012;
    for (final side in [-1, 1]) {
      final c = Offset(
        w / 2 + side * w * 0.265,
        h * 0.72 + float * 0.8 + swing * side,
      );
      canvas.drawCircle(
        c,
        w * 0.052,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(body, Colors.white, 0.40)!, body],
          ).createShader(Rect.fromCircle(center: c, radius: w * 0.052)),
      );
    }
  }

  /// Kafanin yanindaki kucuk kulaklar.
  void _ears(Canvas canvas, Offset c, double r) {
    for (final side in [-1, 1]) {
      final e = Offset(c.dx + side * (r + r * 0.17), c.dy + r * 0.06);
      canvas.drawCircle(
        e,
        r * 0.21,
        Paint()..color = Color.lerp(body, Colors.white, 0.18)!,
      );
      canvas.drawCircle(
        e,
        r * 0.10,
        Paint()..color = accent.withValues(alpha: 0.85),
      );
    }
  }

  /// Tamamen yuvarlak kafa.
  void _head(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.40, -0.46),
          radius: 1.1,
          colors: [
            Color.lerp(body, Colors.white, 0.50)!,
            body,
            Color.lerp(body, const Color(0xFF14091F), 0.55)!,
            const Color(0xFF0C0516),
          ],
          stops: const [0.0, 0.36, 0.82, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Kenar isigi: kure ile ayni gorsel dili kurar, yuzeye cam hissi verir.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.035
        ..shader = SweepGradient(
          colors: [
            accent.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.35),
            accent.withValues(alpha: 0.12),
            accent.withValues(alpha: 0.75),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Sol ustte yumusak bir parlama: yuzeye hacim verir.
    canvas.drawCircle(
      Offset(c.dx - r * 0.34, c.dy - r * 0.40),
      r * 0.26,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  /// Genis vizor, gozler ve yanak noktalari.
  void _visor(Canvas canvas, Offset c, double r, double phase) {
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - r * 0.06),
        width: r * 1.42,
        height: r * 0.86,
      ),
      Radius.circular(r * 0.43),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF291641), Color(0xFF120A24)],
        ).createShader(visor.outerRect),
    );

    final eyeY = visor.center.dy;
    final open = (1 - blink).clamp(0.14, 1.0);

    switch (mood) {
      case RobotMood.speaking:
        const bars = 5;
        final barW = visor.width * 0.052;
        for (var i = 0; i < bars; i++) {
          final a = still
              ? 0.5
              : (math.sin(phase * 2 * math.pi * 2 + i * 0.95) * 0.5 + 0.5);
          final barH = visor.height * (0.20 + a * 0.44);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(
                  visor.center.dx + (i - (bars - 1) / 2) * barW * 2.0,
                  eyeY,
                ),
                width: barW,
                height: barH,
              ),
              Radius.circular(barW),
            ),
            Paint()..color = accent,
          );
        }
      case RobotMood.ended:
        for (final side in [-1, 1]) {
          final e = Offset(visor.center.dx + side * visor.width * 0.22, eyeY);
          canvas.drawLine(
            Offset(e.dx - visor.width * 0.055, e.dy),
            Offset(e.dx + visor.width * 0.055, e.dy),
            Paint()
              ..color = accent.withValues(alpha: 0.8)
              ..strokeWidth = visor.height * 0.11
              ..strokeCap = StrokeCap.round,
          );
        }
      default:
        final pulse = still || mood != RobotMood.listening
            ? 1.0
            : 1 + math.sin(phase * 2 * math.pi * 1.5) * 0.09;
        for (final side in [-1, 1]) {
          final e = Offset(visor.center.dx + side * visor.width * 0.22, eyeY);
          final rr = visor.height * 0.30 * open * pulse;
          canvas.drawCircle(
            e,
            rr * 1.7,
            Paint()
              ..color = accent.withValues(alpha: 0.30)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
          canvas.drawCircle(e, rr, Paint()..color = accent);
          canvas.drawCircle(
            Offset(e.dx + rr * 0.34, e.dy - rr * 0.36),
            rr * 0.32,
            Paint()..color = Colors.white.withValues(alpha: 0.9 * open),
          );
        }
    }

    // Cam yansimasi.
    canvas.save();
    canvas.clipRRect(visor);
    canvas.drawPath(
      Path()
        ..moveTo(visor.left, visor.bottom)
        ..lineTo(visor.left + visor.width * 0.40, visor.top)
        ..lineTo(visor.left + visor.width * 0.58, visor.top)
        ..lineTo(visor.left + visor.width * 0.18, visor.bottom)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.restore();
  }

  /// Kafanin ustunde egik duran ince halka.
  void _halo(Canvas canvas, Offset c, double r, double phase) {
    final tilt = still ? 0.0 : math.sin(phase * 2 * math.pi) * 0.06;
    canvas.save();
    canvas.translate(c.dx, c.dy - r * 1.18);
    canvas.rotate(tilt);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.00, height: r * 0.30),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.085
        ..shader = LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.white, 0.6)!],
        ).createShader(
          Rect.fromCenter(center: Offset.zero, width: r, height: r * 0.3),
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.00, height: r * 0.30),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.085
        ..color = accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.t != t ||
      old.mood != mood ||
      old.blink != blink ||
      old.body != body ||
      old.accent != accent ||
      old.still != still ||
      old.isDark != isDark;
}
