import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Misty mountain-cloud background. All screens are built on top of this.
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
          stops: const [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Misty mountain / cloud scene painted in the background.
          Positioned.fill(
            child: CustomPaint(
              painter: _MistPainter(isDark: isDark),
            ),
          ),
          // Soft ambient glow blobs for depth.
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(
              color: AppPalette.blush.withValues(
                alpha: isDark ? 0.15 : 0.30,
              ),
              size: 240,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _Blob(
              color: AppPalette.cyan.withValues(
                alpha: isDark ? 0.12 : 0.28,
              ),
              size: 280,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Paints subtle misty clouds and distant mountain silhouettes.
class _MistPainter extends CustomPainter {
  _MistPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Distant mountain range (very faint) ---
    final mountainPaint = Paint()
      ..color = (isDark
              ? const Color(0xFF2A5A50)
              : const Color(0xFFC8D8D0))
          .withValues(alpha: isDark ? 0.25 : 0.35);

    final mountains = Path()
      ..moveTo(0, h * 0.42)
      ..lineTo(w * 0.12, h * 0.33)
      ..quadraticBezierTo(w * 0.18, h * 0.28, w * 0.25, h * 0.32)
      ..lineTo(w * 0.35, h * 0.24)
      ..quadraticBezierTo(w * 0.42, h * 0.19, w * 0.50, h * 0.26)
      ..lineTo(w * 0.58, h * 0.22)
      ..quadraticBezierTo(w * 0.65, h * 0.16, w * 0.72, h * 0.25)
      ..lineTo(w * 0.82, h * 0.20)
      ..quadraticBezierTo(w * 0.90, h * 0.15, w, h * 0.28)
      ..lineTo(w, h * 0.50)
      ..lineTo(0, h * 0.50)
      ..close();

    canvas.drawPath(mountains, mountainPaint);

    // --- Fog/mist layers ---
    for (var i = 0; i < 4; i++) {
      final yOffset = h * (0.28 + i * 0.05);
      final alpha = (isDark ? 0.06 : 0.12) - i * 0.02;
      if (alpha <= 0) continue;

      final fogPaint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFF0EDE6))
            .withValues(alpha: alpha.clamp(0.01, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30.0 + i * 12);

      final fog = Path()
        ..moveTo(-w * 0.1, yOffset + h * 0.04)
        ..quadraticBezierTo(
            w * 0.2, yOffset - h * 0.02, w * 0.4, yOffset + h * 0.03)
        ..quadraticBezierTo(
            w * 0.6, yOffset + h * 0.06, w * 0.8, yOffset - h * 0.01)
        ..quadraticBezierTo(
            w * 0.95, yOffset + h * 0.02, w * 1.1, yOffset + h * 0.05)
        ..lineTo(w * 1.1, yOffset + h * 0.12)
        ..lineTo(-w * 0.1, yOffset + h * 0.12)
        ..close();

      canvas.drawPath(fog, fogPaint);
    }

    // --- Soft cloud shapes floating at top ---
    _drawCloud(canvas, Offset(w * 0.18, h * 0.10), w * 0.22,
        isDark ? 0.06 : 0.14);
    _drawCloud(canvas, Offset(w * 0.70, h * 0.08), w * 0.18,
        isDark ? 0.05 : 0.12);
    _drawCloud(canvas, Offset(w * 0.45, h * 0.15), w * 0.25,
        isDark ? 0.04 : 0.10);
  }

  void _drawCloud(Canvas canvas, Offset center, double radius, double alpha) {
    final cloudColor = (isDark ? Colors.white : const Color(0xFFE8E4DD))
        .withValues(alpha: alpha);
    final paint = Paint()
      ..color = cloudColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);

    // Three overlapping circles to form a cloud shape
    canvas.drawCircle(center, radius * 0.5, paint);
    canvas.drawCircle(
        Offset(center.dx - radius * 0.35, center.dy + radius * 0.08),
        radius * 0.38,
        paint);
    canvas.drawCircle(
        Offset(center.dx + radius * 0.35, center.dy + radius * 0.05),
        radius * 0.42,
        paint);
  }

  @override
  bool shouldRepaint(_MistPainter old) => old.isDark != isDark;
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 110, spreadRadius: 40),
          ],
        ),
      ),
    );
  }
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

/// Frosted glass surface.
///
/// `blur` is enabled only for a few prominent cards; regular list items
/// skip the blur to keep scrolling performance smooth.
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
        border: Border.all(color: borderColor ?? tokens.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
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
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: shape, child: surface),
    );
  }
}

/// Gradient pill button for primary actions.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
    this.height = 54,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool busy;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onTap != null && !busy;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: tokens.brandGradient,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(
                color: AppPalette.brand.withValues(alpha: 0.34),
                blurRadius: 22,
                offset: const Offset(0, 8),
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
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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

/// Section title: small, spaced and calm.
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

/// The app's own assistant icon: a glass bubble with a simple face.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: tokens.softGradient,
        border: Border.all(color: tokens.glassBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppPalette.brand.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.3,
          child: CustomPaint(
            painter: _FacePainter(
              color: tokens.isDark ? Colors.white : AppPalette.brandDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final eyeRadius = size.height * 0.17;
    final eyeY = size.height * 0.3;
    canvas.drawCircle(Offset(size.width * 0.22, eyeY), eyeRadius, paint);
    canvas.drawCircle(Offset(size.width * 0.78, eyeY), eyeRadius, paint);

    final smile = Path()
      ..moveTo(size.width * 0.3, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.0,
        size.width * 0.7,
        size.height * 0.72,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.color != color;
}

/// Staggered entrance animation for list items.
///
/// Items appear with increasing delay as `index` grows, giving a flowing
/// cascade effect. Respects the reduced-motion accessibility setting.
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
    final delay = Duration(milliseconds: 60 * widget.index.clamp(0, 8));
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
