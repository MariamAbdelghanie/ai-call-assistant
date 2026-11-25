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

    // Altta yassi bir golge: kurenin havada durdugunu anlatan sey bu.
    final shadowCenter = center.translate(0, core * 1.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: shadowCenter,
        width: core * 1.5,
        height: core * 0.34,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: 0.30 * intensity),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCenter(
            center: shadowCenter,
            width: core * 1.5,
            height: core * 0.34,
          ),
        ),
    );

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

/// Kurenin arkasindaki hareketli zemin.
///
/// Duz lacivert bir dikdortgen kureyi tasiyordu ama sahne olu duruyordu.
/// Burada uc yumusak renk lekesi birbirinden farkli hizlarda dolaniyor;
/// hicbiri kendi basina fark edilmiyor, birlikte zeminin yavasca renk
/// degistirmesini sagliyorlar.
class AuroraStage extends StatefulWidget {
  const AuroraStage({
    super.key,
    required this.child,
    this.active = false,
    this.radius = 28,
    this.light = false,
  });

  final Widget child;

  /// Cagri suruyorsa lekeler daha hizli ve daha parlak.
  final bool active;

  final double radius;

  /// Acik zemin: krem beyaz uzerinde seftali lekeleri. Arama ekraninda
  /// kullaniliyor; koyu sahne kurenin altindaki metinleri de koyulastirip
  /// sayfayi uygulamanin geri kalanindan kopariyordu.
  final bool light;

  @override
  State<AuroraStage> createState() => _AuroraStageState();
}

class _AuroraStageState extends State<AuroraStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.light
                ? const [Color(0xFFFFFBF8), Color(0xFFFFF0E4)]
                : const [AppPalette.indigo, AppPalette.indigoDeep],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _AuroraPainter(
                      phase: _controller.value,
                      strength: widget.active ? 1.0 : 0.6,
                      light: widget.light,
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.phase,
    required this.strength,
    required this.light,
  });

  final double phase;
  final double strength;
  final bool light;

  /// Her leke: renk, yorunge yaricapi, hiz carpani ve baslangic acisi.
  static const _dark = <(Color, double, double, double)>[
    (Color(0xFFFF7A2F), 0.34, 1.0, 0.0),
    (Color(0xFF7A4BD0), 0.30, -0.7, 2.1),
    (Color(0xFF2BB3A3), 0.26, 0.45, 4.2),
  ];

  /// Acik zeminde ayni lekeler daha sicak ve daha soluk; beyazin uzerinde
  /// koyu renkler leke gibi duruyordu.
  static const _lightBlobs = <(Color, double, double, double)>[
    (Color(0xFFFFB07C), 0.34, 1.0, 0.0),
    (Color(0xFFFFD2B0), 0.30, -0.7, 2.1),
    (Color(0xFFFFE0C2), 0.26, 0.45, 4.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = math.min(size.width, size.height);

    for (final (color, orbit, speed, offset) in light ? _lightBlobs : _dark) {
      final angle = offset + phase * 2 * math.pi * speed;
      final pos = center +
          Offset(math.cos(angle), math.sin(angle * 0.8)) * (base * orbit);
      final radius = base * 0.52;
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: (light ? 0.55 : 0.30) * strength),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.strength != strength ||
      oldDelegate.light != light;
}
