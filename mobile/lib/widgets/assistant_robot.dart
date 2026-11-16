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

  /// Her duruma kendi rengi: mavi sakin, pudra konusan, adacayi dinleyen.
  ({Color body, Color aura, Color accent}) _palette() {
    return switch (widget.mood) {
      RobotMood.idle => (
          body: AppPalette.mistBlue,
          aura: AppPalette.mistBlue,
          accent: AppPalette.blush,
        ),
      RobotMood.connecting => (
          body: AppPalette.blush,
          aura: AppPalette.mistBlue,
          accent: AppPalette.mistBlue,
        ),
      RobotMood.listening => (
          body: AppPalette.mistBlue,
          aura: AppPalette.sage,
          accent: AppPalette.blush,
        ),
      RobotMood.speaking => (
          body: AppPalette.blush,
          aura: AppPalette.blush,
          accent: AppPalette.mistBlue,
        ),
      RobotMood.ended => (
          body: const Color(0xFFBFCCC8),
          aura: const Color(0xFFBFCCC8),
          accent: const Color(0xFFBFCCC8),
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
    final wave = still ? 0.0 : math.sin(t * 2 * math.pi);
    final bob = wave * (_active ? h * 0.020 : h * 0.012);
    final cx = w / 2;
    final cy = h * 0.46 + bob;

    _paintAura(canvas, Offset(cx, cy), w);
    _paintShadow(canvas, w, h, bob);
    _paintBody(canvas, cx, cy, w, h);
    _paintHead(canvas, cx, cy, w, h, wave);
  }

  /// Arkadaki yumusak isik ve konusurken acilan halkalar.
  void _paintAura(Canvas canvas, Offset center, double w) {
    canvas.drawCircle(
      center,
      w * 0.40,
      Paint()
        ..color = aura.withValues(alpha: isDark ? 0.34 : 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 38),
    );
    if (!_active || still) return;
    for (var i = 0; i < 3; i++) {
      final phase = (t * 1.7 + i / 3) % 1.0;
      canvas.drawCircle(
        center,
        w * (0.30 + phase * 0.20),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = aura.withValues(alpha: (1 - phase) * 0.40),
      );
    }
  }

  /// Yerdeki yumusak golge: robot yukseldikce kuculup soluyor.
  void _paintShadow(Canvas canvas, double w, double h, double bob) {
    final lift = (bob / (h * 0.02)).clamp(-1.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.88),
        width: w * (0.34 - lift * 0.03),
        height: h * 0.045,
      ),
      Paint()
        ..color = (isDark ? Colors.black : AppPalette.deepSlate)
            .withValues(alpha: (isDark ? 0.34 : 0.16) - lift * 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  /// Govde ve kollar.
  void _paintBody(Canvas canvas, double cx, double cy, double w, double h) {
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + h * 0.26),
        width: w * 0.40,
        height: h * 0.24,
      ),
      Radius.circular(w * 0.13),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(body, Colors.white, 0.55)!,
            Color.lerp(body, Colors.white, 0.10)!,
          ],
        ).createShader(bodyRect.outerRect),
    );

    // Gogusteki isik: nabiz gibi atar.
    final pulse = still ? 0.6 : 0.5 + math.sin(t * 2 * math.pi * 1.6) * 0.5;
    final chest = Offset(cx, cy + h * 0.24);
    canvas.drawCircle(
      chest,
      w * 0.035,
      Paint()..color = accent.withValues(alpha: 0.35 + pulse * 0.45),
    );
    canvas.drawCircle(
      chest,
      w * 0.035,
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Kollar
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + side * w * 0.25, cy + h * 0.25),
            width: w * 0.075,
            height: h * 0.13,
          ),
          Radius.circular(w * 0.04),
        ),
        Paint()..color = Color.lerp(body, Colors.white, 0.35)!,
      );
    }
  }

  /// Kafa, vizor, gozler, agiz ve yanaklar.
  void _paintHead(
      Canvas canvas, double cx, double cy, double w, double h, double wave) {
    final headW = w * 0.56;
    final headH = h * 0.44;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH),
      Radius.circular(headH * 0.40),
    );

    // Anten
    final antennaTop = Offset(cx + wave * w * 0.012, cy - headH / 2 - h * 0.11);
    canvas.drawLine(
      Offset(cx, cy - headH / 2),
      antennaTop,
      Paint()
        ..color = Color.lerp(body, Colors.white, 0.3)!
        ..strokeWidth = w * 0.016
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(antennaTop, w * 0.040, Paint()..color = accent);
    canvas.drawCircle(
      antennaTop,
      w * 0.040,
      Paint()
        ..color = accent.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Kulaklar
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + side * (headW / 2 + w * 0.025), cy),
            width: w * 0.055,
            height: h * 0.11,
          ),
          Radius.circular(w * 0.028),
        ),
        Paint()..color = Color.lerp(body, Colors.white, 0.25)!,
      );
    }

    // Kafa govdesi: ustten acik, altta doygun.
    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(body, Colors.white, 0.68)!,
            Color.lerp(body, Colors.white, 0.08)!,
          ],
        ).createShader(headRect.outerRect),
    );

    // Ust parlama: plastik hissi veren tek vurgu.
    canvas.save();
    canvas.clipRRect(headRect);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - headW * 0.16, cy - headH * 0.34),
        width: headW * 0.56,
        height: headH * 0.28,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.restore();

    // Vizor
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy + headH * 0.02),
        width: headW * 0.76,
        height: headH * 0.52,
      ),
      Radius.circular(headH * 0.24),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF34474F),
            const Color(0xFF1C2A30),
          ],
        ).createShader(visor.outerRect),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    _paintFace(canvas, visor);

    // Yanaklar: pudra tonu, karakterin sicakligini verir.
    for (final side in [-1, 1]) {
      canvas.drawCircle(
        Offset(cx + side * headW * 0.38, cy + headH * 0.14),
        w * 0.026,
        Paint()..color = AppPalette.blush.withValues(alpha: 0.75),
      );
    }
  }

  void _paintFace(Canvas canvas, RRect visor) {
    final eyeY = visor.center.dy - visor.height * 0.10;
    final eyeDx = visor.width * 0.22;
    final open = (1 - blink).clamp(0.10, 1.0);

    for (final side in [-1, 1]) {
      final c = Offset(visor.center.dx + side * eyeDx, eyeY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c,
            width: visor.width * 0.15,
            height: visor.height * 0.34 * open,
          ),
          Radius.circular(visor.width * 0.075),
        ),
        Paint()..color = Colors.white,
      );
      // Gozdeki kucuk isik noktasi
      if (open > 0.5) {
        canvas.drawCircle(
          c.translate(visor.width * 0.035, -visor.height * 0.07),
          visor.width * 0.022,
          Paint()..color = accent.withValues(alpha: 0.9),
        );
      }
    }

    final mouthY = visor.center.dy + visor.height * 0.26;
    switch (mood) {
      case RobotMood.speaking:
        const bars = 5;
        final barW = visor.width * 0.040;
        for (var i = 0; i < bars; i++) {
          final amp = still
              ? 0.5
              : math.sin(t * 2 * math.pi * 2.2 + i * 0.85) * 0.5 + 0.5;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(
                  visor.center.dx + (i - (bars - 1) / 2) * barW * 2.1,
                  mouthY,
                ),
                width: barW,
                height: visor.height * (0.08 + amp * 0.24),
              ),
              Radius.circular(barW),
            ),
            Paint()..color = Colors.white,
          );
        }
      case RobotMood.listening:
        final pulse = still ? 0.5 : math.sin(t * 2 * math.pi * 1.5) * 0.5 + 0.5;
        canvas.drawCircle(
          Offset(visor.center.dx, mouthY),
          visor.width * (0.05 + pulse * 0.022),
          Paint()..color = Colors.white.withValues(alpha: 0.92),
        );
      case RobotMood.ended:
        canvas.drawLine(
          Offset(visor.center.dx - visor.width * 0.11, mouthY),
          Offset(visor.center.dx + visor.width * 0.11, mouthY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = visor.height * 0.07
            ..strokeCap = StrokeCap.round,
        );
      case RobotMood.idle:
      case RobotMood.connecting:
        final smile = Path()
          ..moveTo(visor.center.dx - visor.width * 0.13, mouthY)
          ..quadraticBezierTo(
            visor.center.dx,
            mouthY + visor.height * 0.17,
            visor.center.dx + visor.width * 0.13,
            mouthY,
          );
        canvas.drawPath(
          smile,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = visor.height * 0.07
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) =>
      old.t != t ||
      old.mood != mood ||
      old.blink != blink ||
      old.body != body ||
      old.isDark != isDark;
}
