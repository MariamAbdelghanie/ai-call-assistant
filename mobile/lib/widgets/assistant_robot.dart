import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The assistant's state. The robot changes color and moves according to mood.
enum RobotMood { idle, connecting, listening, speaking, ended }

/// The app's own robot character.
///
/// When speaking its mouth ripples, when listening it breathes, and it
/// blinks every few seconds. Animations respect the "reduced motion" setting.
class AssistantRobot extends StatefulWidget {
  const AssistantRobot({super.key, required this.mood, this.size = 200});

  final RobotMood mood;
  final double size;

  @override
  State<AssistantRobot> createState() => _AssistantRobotState();
}

class _AssistantRobotState extends State<AssistantRobot>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  double _blinkTimer = 0;

  @override
  void initState() {
    super.initState();
    _loop.addListener(_maybeBlink);
  }

  void _maybeBlink() {
    // Blinks approximately every four seconds.
    _blinkTimer += 0.016;
    if (_blinkTimer > 3.6) {
      _blinkTimer = 0;
      if (mounted && !_blink.isAnimating) {
        _blink.forward().then((_) => _blink.reverse());
      }
    }
  }

  @override
  void dispose() {
    _loop.removeListener(_maybeBlink);
    _loop.dispose();
    _blink.dispose();
    super.dispose();
  }

  ({Color body, Color glow, Color face}) _colors(BuildContext context) {
    final tokens = context.tokens;
    return switch (widget.mood) {
      RobotMood.idle => (
          body: AppPalette.brandLight,
          glow: AppPalette.brand,
          face: AppPalette.lightText,
        ),
      RobotMood.connecting => (
          body: AppPalette.lilac,
          glow: AppPalette.lilac,
          face: AppPalette.lightText,
        ),
      RobotMood.listening => (
          body: AppPalette.cyan,
          glow: AppPalette.cyan,
          face: AppPalette.lightText,
        ),
      RobotMood.speaking => (
          body: AppPalette.blush,
          glow: AppPalette.blush,
          face: AppPalette.lightText,
        ),
      RobotMood.ended => (
          body: tokens.muted,
          glow: tokens.muted,
          face: Colors.white,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final colors = _colors(context);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _blink]),
        builder: (context, _) {
          final t = reduceMotion ? 0.0 : _loop.value;
          return CustomPaint(
            painter: _RobotPainter(
              t: t,
              mood: widget.mood,
              body: colors.body,
              glow: colors.glow,
              face: colors.face,
              blink: _blink.value,
              isDark: context.tokens.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({
    required this.t,
    required this.mood,
    required this.body,
    required this.glow,
    required this.face,
    required this.blink,
    required this.isDark,
  });

  final double t;
  final RobotMood mood;
  final Color body;
  final Color glow;
  final Color face;
  final double blink;
  final bool isDark;

  bool get _active =>
      mood == RobotMood.listening ||
      mood == RobotMood.speaking ||
      mood == RobotMood.connecting;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bob = math.sin(t * 2 * math.pi) * (_active ? h * 0.018 : h * 0.008);
    final center = Offset(w / 2, h / 2 + bob);

    // Soft glow behind the robot
    canvas.drawCircle(
      center,
      w * 0.42,
      Paint()
        ..color = glow.withValues(alpha: isDark ? 0.34 : 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );

    // Expanding rings when speaking or connecting
    if (mood == RobotMood.speaking || mood == RobotMood.connecting) {
      for (var i = 0; i < 3; i++) {
        final phase = (t * 1.8 + i / 3) % 1.0;
        canvas.drawCircle(
          center,
          w * (0.34 + phase * 0.16),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = glow.withValues(alpha: (1 - phase) * 0.35),
        );
      }
    }

    final headW = w * 0.58;
    final headH = h * 0.50;
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: headW, height: headH),
      Radius.circular(headH * 0.38),
    );

    // Antenna
    final antennaBase = Offset(center.dx, center.dy - headH / 2);
    final antennaTop = Offset(
      center.dx + math.sin(t * 2 * math.pi) * (_active ? w * 0.016 : 0),
      antennaBase.dy - h * 0.12,
    );
    canvas.drawLine(
      antennaBase,
      antennaTop,
      Paint()
        ..color = body.withValues(alpha: 0.9)
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      antennaTop,
      w * 0.038,
      Paint()..color = glow,
    );
    canvas.drawCircle(
      antennaTop,
      w * 0.038,
      Paint()
        ..color = glow.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Ears
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + side * (headW / 2 + w * 0.03),
                center.dy + h * 0.02),
            width: w * 0.06,
            height: h * 0.14,
          ),
          Radius.circular(w * 0.03),
        ),
        Paint()..color = body.withValues(alpha: 0.85),
      );
    }

    // Body (head)
    canvas.drawRRect(
      headRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(body, Colors.white, 0.35)!,
            body,
          ],
        ).createShader(headRect.outerRect),
    );
    canvas.drawRRect(
      headRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.6),
    );

    // Face screen
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + h * 0.005),
        width: headW * 0.74,
        height: headH * 0.56,
      ),
      Radius.circular(headH * 0.22),
    );
    canvas.drawRRect(
      faceRect,
      Paint()..color = isDark
          ? const Color(0xFF0E2420)
          : const Color(0xFF1A3B34),
    );

    final eyeY = faceRect.center.dy - faceRect.height * 0.12;
    final eyeDx = faceRect.width * 0.22;
    final eyeOpen = (1 - blink).clamp(0.12, 1.0);
    final eyePaint = Paint()..color = Colors.white;

    for (final side in [-1, 1]) {
      final eyeCenter = Offset(faceRect.center.dx + side * eyeDx, eyeY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: eyeCenter,
            width: faceRect.width * 0.14,
            height: faceRect.height * 0.30 * eyeOpen,
          ),
          Radius.circular(faceRect.width * 0.07),
        ),
        eyePaint,
      );
    }

    // Mouth: changes based on mood
    final mouthY = faceRect.center.dy + faceRect.height * 0.24;
    switch (mood) {
      case RobotMood.speaking:
        // Speech wave
        const bars = 5;
        final barW = faceRect.width * 0.045;
        for (var i = 0; i < bars; i++) {
          final phase = t * 2 * math.pi * 2 + i * 0.9;
          final amp = (math.sin(phase) * 0.5 + 0.5);
          final barH = faceRect.height * (0.08 + amp * 0.22);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(
                  faceRect.center.dx + (i - (bars - 1) / 2) * barW * 2.0,
                  mouthY,
                ),
                width: barW,
                height: barH,
              ),
              Radius.circular(barW),
            ),
            Paint()..color = Colors.white,
          );
        }
      case RobotMood.listening:
        final pulse = 0.5 + math.sin(t * 2 * math.pi * 1.4) * 0.5;
        canvas.drawCircle(
          Offset(faceRect.center.dx, mouthY),
          faceRect.width * (0.055 + pulse * 0.02),
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
      case RobotMood.ended:
        canvas.drawLine(
          Offset(faceRect.center.dx - faceRect.width * 0.12, mouthY),
          Offset(faceRect.center.dx + faceRect.width * 0.12, mouthY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.85)
            ..strokeWidth = faceRect.height * 0.07
            ..strokeCap = StrokeCap.round,
        );
      case RobotMood.idle:
      case RobotMood.connecting:
        final smile = Path()
          ..moveTo(faceRect.center.dx - faceRect.width * 0.14, mouthY)
          ..quadraticBezierTo(
            faceRect.center.dx,
            mouthY + faceRect.height * 0.18,
            faceRect.center.dx + faceRect.width * 0.14,
            mouthY,
          );
        canvas.drawPath(
          smile,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = faceRect.height * 0.07
            ..strokeCap = StrokeCap.round,
        );
    }

    // Cheeks
    for (final side in [-1, 1]) {
      canvas.drawCircle(
        Offset(center.dx + side * headW * 0.40, center.dy + headH * 0.12),
        w * 0.026,
        Paint()..color = AppPalette.blush.withValues(alpha: 0.65),
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
