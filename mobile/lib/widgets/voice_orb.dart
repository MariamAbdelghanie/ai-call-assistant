import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gorusme ekranindaki parlak kure.
///
/// Robot yerine soyut bir kure kullanilir: sesli asistan arayuzlerinde
/// beklenen gorsel budur ve konusma siddetine gore nabiz atmasi, karakter
/// cizmekten daha az dikkat dagitir.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    required this.size,
    this.speaking = false,
    this.listening = false,
    this.dim = false,
  });

  final double size;

  /// Asistan konusuyor: kure daha hizli ve genis nabiz atar.
  final bool speaking;

  /// Mikrofon acik ve arayan konusuyor.
  final bool listening;

  /// Bagli degil: renkler soner.
  final bool dim;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          painter: _OrbPainter(
            t: reduceMotion ? 0.0 : _loop.value,
            speaking: widget.speaking,
            listening: widget.listening,
            dim: widget.dim,
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.t,
    required this.speaking,
    required this.listening,
    required this.dim,
  });

  final double t;
  final bool speaking;
  final bool listening;
  final bool dim;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = size.width * 0.33;

    final beat = speaking
        ? math.sin(t * 2 * math.pi * 3) * 0.030
        : listening
            ? math.sin(t * 2 * math.pi * 1.6) * 0.018
            : math.sin(t * 2 * math.pi) * 0.008;
    final r = base * (1 + beat);
    final k = dim ? 0.75 : 1.0;

    const cyan = Color(0xFF3BE0FF);
    const blue = Color(0xFF5B6BFF);
    const magenta = Color(0xFFFF4FD8);
    const orange = Color(0xFFFF8A5B);

    final rect = Rect.fromCircle(center: c, radius: r);
    // Renkler kurenin KENARINDA toplanir, merkez neredeyse siyah kalir:
    // referanstaki sabun kabarcigi etkisi boyle olusuyor.
    final spin = t * 2 * math.pi;

    // 1) Disarida renkli bulut (bloom).
    for (final (color, angle, dist, blur, alpha) in <(Color, double, double, double, double)>[
      (cyan, spin + math.pi * 0.85, 0.72, 52.0, 0.42),
      (magenta, spin + math.pi * 1.75, 0.70, 50.0, 0.38),
      (blue, spin + math.pi * 0.25, 0.62, 44.0, 0.26),
    ]) {
      final pc = Offset(
        c.dx + math.cos(angle) * r * dist,
        c.dy + math.sin(angle) * r * dist,
      );
      canvas.drawCircle(
        pc,
        r * 0.85,
        Paint()
          ..color = color.withValues(alpha: alpha * k)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    // 2) Konusurken disa acilan halkalar.
    if (speaking || listening) {
      for (var i = 0; i < 3; i++) {
        final p = ((t * (speaking ? 2.2 : 1.3)) + i / 3) % 1.0;
        canvas.drawCircle(
          c,
          r * (1.08 + p * 0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = (speaking ? magenta : cyan)
                .withValues(alpha: (1 - p) * 0.35),
        );
      }
    }

    // 3) Koyu govde.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.15, -0.20),
          radius: 1.0,
          colors: [
            Color(0xFF17122B),
            Color(0xFF0B0718),
            Color(0xFF04020A),
          ],
          stops: [0.0, 0.62, 1.0],
        ).createShader(rect),
    );

    // 4) Kenar kusaklari: kurenin icinde, kenara yapisik renk yaylari.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    for (final (color, angle, thick, alpha) in <(Color, double, double, double)>[
      (cyan, spin + math.pi * 0.88, 0.40, 0.95),
      (blue, spin + math.pi * 1.10, 0.52, 0.55),
      (magenta, spin + math.pi * 1.80, 0.42, 0.90),
      (orange, spin + math.pi * 1.98, 0.30, 0.45),
    ]) {
      // Merkezi disari kaydirilmis bir daire, kenarda hilal birakir.
      final oc = Offset(
        c.dx + math.cos(angle) * r * 0.42,
        c.dy + math.sin(angle) * r * 0.42,
      );
      canvas.drawCircle(
        oc,
        r * (0.78 + thick * 0.25),
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.0),
              color.withValues(alpha: alpha * 0.55 * k),
              color.withValues(alpha: alpha * k),
            ],
            stops: const [0.55, 0.85, 1.0],
          ).createShader(
            Rect.fromCircle(center: oc, radius: r * (0.78 + thick * 0.25)),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    canvas.restore();

    // 5) Ince dis cember: kureye net bir sinir verir.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = SweepGradient(
          colors: [
            cyan.withValues(alpha: 0.9 * k),
            blue.withValues(alpha: 0.5 * k),
            magenta.withValues(alpha: 0.9 * k),
            orange.withValues(alpha: 0.4 * k),
            cyan.withValues(alpha: 0.9 * k),
          ],
          transform: GradientRotation(spin),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t ||
      old.speaking != speaking ||
      old.listening != listening ||
      old.dim != dim;
}

/// Kurenin altinda duran kucuk ses dalgasi.
class OrbWaveform extends StatefulWidget {
  const OrbWaveform({super.key, required this.active, this.color});

  final bool active;
  final Color? color;

  @override
  State<OrbWaveform> createState() => _OrbWaveformState();
}

class _OrbWaveformState extends State<OrbWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final color = widget.color ?? AppPalette.brandLight;

    return SizedBox(
      width: 86,
      height: 20,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final t = reduceMotion || !widget.active ? 0.0 : _loop.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 11; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.6),
                  child: Container(
                    width: 2.6,
                    height: widget.active
                        ? 4 + (math.sin(t * 2 * math.pi * 2 + i * 0.7) * 0.5 + 0.5) * 14
                        : 4,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: widget.active ? 0.9 : 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
