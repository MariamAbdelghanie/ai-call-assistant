import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum OrbState { idle, connecting, listening, speaking, ended }

/// Gorusmenin kalbi: durumu renk ve hareketle anlatan canli kure.
/// Hareket, erisilebilirlik icin "azaltilmis hareket" ayarina saygi duyar.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.state,
    this.size = 220,
    this.level = 0.0,
  });

  final OrbState state;
  final double size;

  /// 0..1 arasi ses seviyesi; kure bu oranda genisler.
  final double level;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _colors(BuildContext context) {
    final tokens = context.tokens;
    return switch (widget.state) {
      OrbState.idle => [AppPalette.brandDeep, AppPalette.brand],
      OrbState.connecting => [tokens.pending, AppPalette.pink],
      OrbState.listening => [AppPalette.brand, AppPalette.pink],
      OrbState.speaking => [AppPalette.pink, tokens.success],
      OrbState.ended => [tokens.muted, tokens.muted],
    };
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final colors = _colors(context);
    final active = widget.state == OrbState.listening ||
        widget.state == OrbState.speaking ||
        widget.state == OrbState.connecting;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = reduceMotion ? 0.0 : _controller.value;
          return CustomPaint(
            painter: _OrbPainter(
              t: t,
              colors: colors,
              active: active && !reduceMotion,
              level: widget.level.clamp(0.0, 1.0),
            ),
            child: child,
          );
        },
        child: Center(
          child: AnimatedSwitcher(
            duration: AppTheme.normal,
            child: Icon(
              switch (widget.state) {
                OrbState.idle => Icons.mic_none_rounded,
                OrbState.connecting => Icons.wifi_tethering_rounded,
                OrbState.listening => Icons.graphic_eq_rounded,
                OrbState.speaking => Icons.volume_up_rounded,
                OrbState.ended => Icons.call_end_rounded,
              },
              key: ValueKey(widget.state),
              size: widget.size * 0.17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.t,
    required this.colors,
    required this.active,
    required this.level,
  });

  final double t;
  final List<Color> colors;
  final bool active;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Disa dogru acilan halkalar: konusma sirasinda daha belirgin.
    if (active) {
      for (var i = 0; i < 3; i++) {
        final phase = (t * 1.6 + i / 3) % 1.0;
        final radius = maxRadius * (0.55 + phase * 0.45);
        final opacity = (1 - phase) * 0.28;
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = colors.last.withValues(alpha: opacity),
        );
      }
    }

    // Yumusak parlama
    canvas.drawCircle(
      center,
      maxRadius * 0.78,
      Paint()
        ..color = colors.first.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Ana kure: ses seviyesiyle hafifce nefes alir.
    final breathe = active ? math.sin(t * 2 * math.pi) * 0.012 : 0.0;
    final coreRadius = maxRadius * (0.52 + breathe + level * 0.06);
    final rect = Rect.fromCircle(center: center, radius: coreRadius);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          transform: GradientRotation(t * math.pi * 2),
          colors: [colors.first, colors.last, colors.first],
        ).createShader(rect),
    );

    // Ic aydinlik
    canvas.drawCircle(
      center.translate(-coreRadius * 0.18, -coreRadius * 0.2),
      coreRadius * 0.45,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t ||
      old.active != active ||
      old.level != level ||
      old.colors != colors;
}
