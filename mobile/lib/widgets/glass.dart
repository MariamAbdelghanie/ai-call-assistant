import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_icon.dart';

/// Koyu mor zemin: neon halelerle derinlik verir, icerigi one cikarir.
/// All screens are rendered on top of this atmospheric surface.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mesh = context.tokens.mesh;
    final isDark = context.tokens.isDark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: mesh,
          stops: const [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soyut zemin deseni: halkalar, yumusak isik ve kenar karartmasi.
          Positioned.fill(
            child: CustomPaint(painter: _AuraPainter(isDark: isDark)),
          ),
          child,
        ],
      ),
    );
  }
}

/// Sakin, soyut zemin deseni.
///
/// Fotograf yerine birkac buyuk, cok yumusak sekil kullanir: ic ice halkalar,
/// genis bir isik yayi ve kenarlarda hafif bir karartma. Amac dikkat dagitmadan
/// derinlik hissi vermek; bu yuzden tum degerler dusuk opaklikta tutulur.
class _AuraPainter extends CustomPainter {
  _AuraPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Acik temada zemin neredeyse duz kalir; renk ve isik koyu temaya aittir.
    if (!isDark) {
      _softBlob(canvas, size, Offset(size.width * 0.82, -size.height * 0.06),
          size.width * 0.62, AppPalette.brand, 0.07);
      return;
    }

    final w = size.width;
    final h = size.height;

    // 1) Ust ve alt kosede genis neon halesi.
    _softBlob(canvas, size, Offset(w * 0.86, -h * 0.06), w * 0.62,
        AppPalette.brand, 0.10);
    _softBlob(canvas, size, Offset(w * 0.04, h * 0.96), w * 0.56,
        AppPalette.violet, 0.08);

    // 2) Akan isik seritleri: referanstaki "aurora" hissini veren ogeler.
    for (var i = 0; i < 3; i++) {
      final baseY = h * (0.20 + i * 0.26);
      final amp = h * (0.055 + i * 0.012);
      final path = Path()..moveTo(-w * 0.08, baseY);
      const steps = 40;
      for (var s = 1; s <= steps; s++) {
        final x = -w * 0.08 + (w * 1.16) * (s / steps);
        final y = baseY + math.sin((s / steps) * math.pi * 2 + i) * amp;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = (i.isEven ? AppPalette.brandLight : AppPalette.blush)
              .withValues(alpha: 0.05 - i * 0.012)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // 3) Merkezden disa acilan ince halkalar.
    final ringCenter = Offset(w * 0.5, h * 0.40);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        ringCenter,
        w * (0.30 + i * 0.15),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = AppPalette.brandLight
              .withValues(alpha: 0.035 * (1 - i * 0.2)),
      );
    }

    // 4) Kenarlarda hafif karartma: icerigi one cikarir.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            const Color(0xFF000000).withValues(alpha: 0.75),
          ],
          stops: const [0.40, 1.0],
        ).createShader(Offset.zero & size),
    );
  }

  /// Tek bir yumusak renk lekesi.
  void _softBlob(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_AuraPainter old) => old.isDark != isDark;
}



/// Gradient background + transparent scaffold + optional AppBar.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.titleWidget,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: (title == null && titleWidget == null)
            ? null
            : AppBar(
                title: titleWidget ?? Text(title!),
                actions: actions,
                leading: leading,
              ),
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

/// Frosted glass surface matching Mindora component cards.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.radius,
    this.blur = false,
    this.strong = false,
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final bool strong;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = BorderRadius.circular(radius);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (strong ? tokens.glassStrong : tokens.glass)
            : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(
          color: borderColor ?? tokens.glassBorder,
          width: 1.2,
        ),
        // Koyu zeminde derinlik golgeyle degil, yuzeyin kendi isigiyla
        // kurulur; acik temada ise yumusak bir golge kullanilir.
        boxShadow: tokens.isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF05020A).withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: AppPalette.deepSlate.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          if (tokens.isDark)
            Positioned(
              left: radius * 0.6,
              right: radius * 0.6,
              top: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: shape,
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ],
      ),
    );

    if (blur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: surface,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: tokens.shadow,
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: shape, child: surface),
    );
  }
}

/// Gradient pill button blending the Mindora colors with glowing shadow.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.height = 54,
    this.expand = true,
    this.useFourColors = true,
  });

  final String label;
  final AppIcon? icon;
  final VoidCallback? onTap;
  final bool busy;
  final double height;
  final bool expand;
  final bool useFourColors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onTap != null && !busy;

    final gradient = useFourColors ? tokens.fourColorGradient : tokens.brandGradient;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: AppPalette.sage.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(height / 2),
              onTap: enabled ? onTap : null,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            SoftIcon(icon!, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title: clean and spaced.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Mindora Zen AI Agent Avatar: an elegant crystal energy orb blending the 4 colors.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: tokens.fourColorGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.sage.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.65,
          height: size * 0.65,
          child: CustomPaint(
            painter: _MindoraCorePainter(
              isDark: tokens.isDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for the compact Mindora Zen energy core in the avatar.
class _MindoraCorePainter extends CustomPainter {
  _MindoraCorePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Outer subtle orbital ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: w * 0.95, height: h * 0.52),
      ringPaint,
    );

    // Inner glowing core
    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, w * 0.18, corePaint);

    // Radiant energy dots
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(center.dx - w * 0.34, center.dy), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.34, center.dy), w * 0.05, dotPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - h * 0.32), w * 0.05, dotPaint);
  }

  @override
  bool shouldRepaint(_MindoraCorePainter old) => false;
}

/// Staggered entrance animation for list items.
class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 0.06,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 55 * widget.index.clamp(0, 8));
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) return widget.child;

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.offset),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
