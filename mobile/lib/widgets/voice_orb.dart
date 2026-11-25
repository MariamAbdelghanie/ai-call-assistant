import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gorusme ekranindaki sakin ses gostergesi.
///
/// Onceki surum neon bir kuroydu; acik temali bir is uygulamasinda bu yabanci
/// duruyordu. Yerine yumusak bir disk kondu: dinlerken yavasca nefes alir,
/// asistan konusurken biraz buyur ve halkalari belirginlesir. Disarida
/// goruldugu kadariyla ayni arayuz (size / speaking / listening / dim)
/// korundugu icin cagri ekraninda baska bir degisiklik gerekmez.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    this.size = 260,
    this.speaking = false,
    this.listening = false,
    this.dim = false,
  });

  final double size;

  /// Asistan konusuyor.
  final bool speaking;

  /// Mikrofon acik ve arayani dinliyor.
  final bool listening;

  /// Cagri aktif degil: her sey sakinlesir.
  final bool dim;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  /// Renk donusu nefesten cok daha yavas: ikisi ayni hizda olunca
  /// hareket titrek gorunuyordu.
  late final AnimationController _hue = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    _hue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final active = widget.speaking || widget.listening;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _hue]),
          builder: (context, _) {
            // Nefes: konusurken daha belirgin, beklerken cok hafif.
            final wave = math.sin(_controller.value * 2 * math.pi);
            final amplitude = widget.speaking
                ? 0.045
                : widget.listening
                    ? 0.022
                    : 0.008;
            final scale = 1 + wave * amplitude;

            // Suzulme: kure yerinde durmak yerine cok yavas yukari
            // asagi gidiyor. Hareket kucuk (birkac piksel) ama ekranin
            // canli oldugu hissini veren sey bu.
            final float = wave * (widget.dim ? 2.0 : 6.0);

            return Transform.translate(
              offset: Offset(0, float),
              child: Transform.scale(
                scale: widget.dim ? 1 : scale,
                child: CustomPaint(
                  painter: _OrbPainter(
                    isDark: tokens.isDark,
                    intensity: widget.dim ? 0.35 : (active ? 1.0 : 0.65),
                    phase: _controller.value,
                    // Cagri sirasinda renk yavasca donuyor: turuncudan
                    // mercana, oradan menekseye ve lacivere. Beklerken
                    // sabit turuncu kaliyor ki ekran huzursuz olmasin.
                    hueShift: active ? _hue.value : 0,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.isDark,
    required this.intensity,
    required this.phase,
    required this.hueShift,
  });

  final bool isDark;

  /// 0..1 arasi canlilik; bekleme halinde dusuk tutulur.
  final double intensity;
  final double phase;

  /// 0..1 arasi renk donusu. Cagri sirasinda doner, beklerken 0 kalir.
  final double hueShift;

  /// Kurenin donguye girdigi renkler. Hepsi paletin icinden: turuncu,
  /// mercan, menekse ve lacivert. Rastgele gokkusagi degil, cunku
  /// uygulamanin geri kalaniyla ayni ailede kalmasi gerekiyor.
  static const _cycle = <Color>[
    Color(0xFFFF8A4B),
    Color(0xFFF2542D),
    Color(0xFFE0457B),
    Color(0xFF7A4BD0),
    Color(0xFF2E5BD4),
    Color(0xFFFF8A4B),
  ];

  /// Donguyu 0..1 arasinda yumusak bir renge cevirir.
  Color _tone(double t, {double offset = 0}) {
    final p = ((t + offset) % 1.0) * (_cycle.length - 1);
    final i = p.floor();
    return Color.lerp(_cycle[i], _cycle[i + 1], p - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final core = radius * 0.58;

    final top = _tone(hueShift);
    final bottom = _tone(hueShift, offset: 0.12);

    // Hale: kurenin disina tasan yumusak isik. Koyu zeminde kure bunun
    // sayesinde ekrana yapisik degil, havada duruyor gibi gorunuyor.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            top.withValues(alpha: 0.38 * intensity),
            top.withValues(alpha: 0.10 * intensity),
            top.withValues(alpha: 0),
          ],
          stops: const [0.30, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Disaridan iceri dogru genisleyen ince halkalar.
    for (var i = 3; i >= 1; i--) {
      final t = (phase + i / 3) % 1.0;
      final ringRadius = core + (radius - core) * t;
      final fade = (1 - t) * 0.45 * intensity;
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _tone(hueShift, offset: i * 0.05)
              .withValues(alpha: fade),
      );
    }

    // Yumusak dis halka.
    canvas.drawCircle(
      center,
      core + 14,
      Paint()
        ..style = PaintingStyle.fill
        ..color = top.withValues(alpha: 0.12 * intensity),
    );

    // Govde: lacivertten beje dogru cok yumusak bir gecis.
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          top,
          Color.lerp(bottom, Colors.black, isDark ? 0.28 : 0.18)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: core));
    canvas.drawCircle(center, core, body);

    // Ust solda hafif bir isik: yuzeye hacim verir.
    canvas.drawCircle(
      center.translate(-core * 0.28, -core * 0.3),
      core * 0.52,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.14 : 0.26),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: center.translate(-core * 0.28, -core * 0.3),
            radius: core * 0.52,
          ),
        ),
    );

    // Ince kenar cizgisi.
    canvas.drawCircle(
      center,
      core,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.22),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.intensity != intensity ||
      oldDelegate.hueShift != hueShift ||
      oldDelegate.isDark != isDark;
}

/// Kurenin altindaki ince ses cubuklari.
class OrbWaveform extends StatefulWidget {
  const OrbWaveform({super.key, this.active = false, this.barCount = 13});

  final bool active;
  final int barCount;

  @override
  State<OrbWaveform> createState() => _OrbWaveformState();
}

class _OrbWaveformState extends State<OrbWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: 26,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.barCount; i++) ...[
                _Bar(
                  active: widget.active,
                  phase: _controller.value,
                  index: i,
                  count: widget.barCount,
                  color: widget.active
                      ? AppPalette.orange
                      : tokens.muted.withValues(alpha: 0.45),
                ),
                if (i != widget.barCount - 1) const SizedBox(width: 5),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.active,
    required this.phase,
    required this.index,
    required this.count,
    required this.color,
  });

  final bool active;
  final double phase;
  final int index;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Ortadaki cubuklar en uzun; dalga soldan saga akar.
    final middle = (count - 1) / 2;
    final distance = (index - middle).abs() / middle;
    final envelope = 1 - distance * 0.7;
    final wave = math.sin((phase * 2 * math.pi) + index * 0.55).abs();
    final height = active ? 5 + 20 * wave * envelope : 4 + 3 * envelope;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
