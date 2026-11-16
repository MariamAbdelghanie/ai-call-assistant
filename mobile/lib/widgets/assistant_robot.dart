import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The assistant's mood state. The agent changes its aura and movement according to this.
enum RobotMood { idle, connecting, listening, speaking, ended }

/// Mindora Zen AI Agent:
/// An ethereal, multi-layered energy sphere with rotating orbital rings,
/// breathing core, and dynamic soundwave harmonics blending the 4 Mindora colors:
/// #5E887E (Sage), #A7C7E7 (Mist Blue), #2F3E46 (Deep Slate), #F1F5F4 (Mist White).
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
    duration: const Duration(seconds: 6),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _loop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  ({Color core, Color aura, Color ring, Color accent}) _colors() {
    return switch (widget.mood) {
      RobotMood.idle => (
          core: AppPalette.sage,
          aura: AppPalette.mistBlue,
          ring: AppPalette.mistWhite,
          accent: AppPalette.blush,
        ),
      RobotMood.connecting => (
          core: AppPalette.mistBlue,
          aura: AppPalette.sage,
          ring: AppPalette.mistWhite,
          accent: AppPalette.blush,
        ),
      RobotMood.listening => (
          core: const Color(0xFF4EA89B),
          aura: AppPalette.mistBlue,
          ring: Colors.white,
          accent: AppPalette.sage,
        ),
      RobotMood.speaking => (
          core: AppPalette.blush,
          aura: AppPalette.mistBlue,
          ring: AppPalette.mistWhite,
          accent: AppPalette.sage,
        ),
      RobotMood.ended => (
          core: AppPalette.lightMuted,
          aura: const Color(0xFFBACDC8),
          ring: Colors.white70,
          accent: AppPalette.lightMuted,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final colors = _colors();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _pulse]),
        builder: (context, _) {
          final t = reduceMotion ? 0.0 : _loop.value;
          final p = reduceMotion ? 0.5 : _pulse.value;
          return CustomPaint(
            painter: _MindoraAgentPainter(
              t: t,
              pulse: p,
              mood: widget.mood,
              coreColor: colors.core,
              auraColor: colors.aura,
              ringColor: colors.ring,
              accentColor: colors.accent,
              isDark: context.tokens.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _MindoraAgentPainter extends CustomPainter {
  _MindoraAgentPainter({
    required this.t,
    required this.pulse,
    required this.mood,
    required this.coreColor,
    required this.auraColor,
    required this.ringColor,
    required this.accentColor,
    required this.isDark,
  });

  final double t;
  final double pulse;
  final RobotMood mood;
  final Color coreColor;
  final Color auraColor;
  final Color ringColor;
  final Color accentColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2 + math.sin(t * 2 * math.pi) * (h * 0.015));

    // 1. Soft atmospheric background aura (breathing glow)
    final auraRadius = w * (0.38 + pulse * 0.07);
    final auraPaint = Paint()
      ..color = auraColor.withValues(alpha: isDark ? 0.28 : 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.20);
    canvas.drawCircle(center, auraRadius, auraPaint);

    // 2. Ripple rings during active states (speaking, connecting, listening)
    if (mood == RobotMood.speaking ||
        mood == RobotMood.connecting ||
        mood == RobotMood.listening) {
      final rippleCount = mood == RobotMood.speaking ? 4 : 3;
      for (var i = 0; i < rippleCount; i++) {
        final phase = (t * (mood == RobotMood.speaking ? 2.2 : 1.5) + i / rippleCount) % 1.0;
        final radius = w * (0.28 + phase * 0.22);
        final opacity = (1.0 - phase) * (isDark ? 0.40 : 0.45);

        final ripplePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = (i.isEven ? coreColor : auraColor).withValues(alpha: opacity);
        canvas.drawCircle(center, radius, ripplePaint);
      }
    }

    // 3. Gyroscopic 3D Orbital Rings (rotating around the core)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = ringColor.withValues(alpha: isDark ? 0.60 : 0.85);

    // First orbital ring (tilted)
    final angle1 = t * 2 * math.pi;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.38 + math.sin(angle1 * 0.5) * 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * (0.64 + pulse * 0.04),
        height: h * (0.26 + math.cos(angle1) * 0.06),
      ),
      ringPaint,
    );

    // Second orbital ring (opposing tilt)
    final angle2 = -t * 2 * math.pi * 0.8;
    canvas.rotate(-0.76);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * (0.68 + pulse * 0.03),
        height: h * (0.24 + math.sin(angle2) * 0.05),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accentColor.withValues(alpha: isDark ? 0.50 : 0.70),
    );

    // Satellite orbital node on the first ring
    final nodeX = math.cos(angle1) * (w * 0.32);
    final nodeY = math.sin(angle1) * (h * 0.13);
    final nodePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(nodeX, nodeY), w * 0.024, nodePaint);
    canvas.drawCircle(
      Offset(nodeX, nodeY),
      w * 0.035,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.restore();

    // 4. Glassmorphic Central Sphere (Blending the 4 Mindora colors)
    final coreRadius = w * 0.22;
    final coreRect = Rect.fromCircle(center: center, radius: coreRadius);

    final coreGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: [
        Colors.white,
        Color.lerp(coreColor, AppPalette.mistBlue, 0.45)!,
        coreColor,
        AppPalette.deepSlate,
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );

    final spherePaint = Paint()..shader = coreGradient.createShader(coreRect);
    canvas.drawCircle(center, coreRadius, spherePaint);

    // Specular highlight (crystalline sheen on top-left of sphere)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.45 : 0.65)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 0.3);
    canvas.drawCircle(
      Offset(center.dx - coreRadius * 0.32, center.dy - coreRadius * 0.32),
      coreRadius * 0.35,
      highlightPaint,
    );

    // Outer rim glow for the sphere
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, coreRadius, rimPaint);

    // 5. Reactive Center Feature (Harmonic Voice Wave or Serene Zen Core)
    if (mood == RobotMood.speaking) {
      // Dynamic fluid sound bars
      const barCount = 5;
      final barWidth = coreRadius * 0.14;
      for (var i = 0; i < barCount; i++) {
        final phase = t * 2 * math.pi * 2.5 + i * 0.85;
        final wave = (math.sin(phase) * 0.5 + 0.5);
        final barHeight = coreRadius * (0.30 + wave * 0.75);

        final x = center.dx + (i - (barCount - 1) / 2) * barWidth * 1.9;
        final barRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, center.dy),
            width: barWidth,
            height: barHeight,
          ),
          Radius.circular(barWidth / 2),
        );
        canvas.drawRRect(barRect, Paint()..color = Colors.white);
      }
    } else if (mood == RobotMood.listening) {
      // Concentric listening wave rings
      final pulseRadius = coreRadius * (0.35 + pulse * 0.30);
      canvas.drawCircle(
        center,
        pulseRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withValues(alpha: 0.9),
      );
      canvas.drawCircle(
        center,
        coreRadius * 0.20,
        Paint()..color = Colors.white,
      );
    } else {
      // Idle / Connecting / Ended: Mindful breathing lotus or zen light core
      final zenRadius = coreRadius * (0.24 + pulse * 0.06);
      canvas.drawCircle(
        center,
        zenRadius,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Subtle horizontal light flare
      canvas.drawLine(
        Offset(center.dx - coreRadius * 0.55, center.dy),
        Offset(center.dx + coreRadius * 0.55, center.dy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MindoraAgentPainter old) =>
      old.t != t ||
      old.pulse != pulse ||
      old.mood != mood ||
      old.coreColor != coreColor ||
      old.auraColor != auraColor ||
      old.isDark != isDark;
}
