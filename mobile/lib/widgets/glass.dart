import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Serene misty mountain and cloud background, matching the Mindora UI design.
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
          // Background misty mountain landscape with clouds & lake reflection
          Positioned.fill(
            child: CustomPaint(
              painter: _MindoraNaturePainter(isDark: isDark),
            ),
          ),
          // Ambient depth glow spots in Mindora palette tones
          Positioned(
            top: -60,
            right: -40,
            child: _GlowBlob(
              color: AppPalette.mistBlue.withValues(
                alpha: isDark ? 0.16 : 0.28,
              ),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -80,
            left: -50,
            child: _GlowBlob(
              color: AppPalette.sage.withValues(
                alpha: isDark ? 0.14 : 0.24,
              ),
              size: 290,
            ),
          ),
          Positioned(
            top: 220,
            left: -80,
            child: _GlowBlob(
              color: AppPalette.blush.withValues(
                alpha: isDark ? 0.10 : 0.18,
              ),
              size: 220,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Custom painter for the Mindora misty lake, pine ridge mountains, and rolling clouds.
class _MindoraNaturePainter extends CustomPainter {
  _MindoraNaturePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Far Distant Mountain Range ---
    final farMountainColor = (isDark
            ? const Color(0xFF243B36)
            : const Color(0xFFBACDC8))
        .withValues(alpha: isDark ? 0.35 : 0.45);

    final farMountainPath = Path()
      ..moveTo(0, h * 0.44)
      ..lineTo(w * 0.10, h * 0.36)
      ..quadraticBezierTo(w * 0.16, h * 0.31, w * 0.24, h * 0.35)
      ..lineTo(w * 0.36, h * 0.26)
      ..quadraticBezierTo(w * 0.44, h * 0.21, w * 0.52, h * 0.28)
      ..lineTo(w * 0.62, h * 0.23)
      ..quadraticBezierTo(w * 0.70, h * 0.17, w * 0.78, h * 0.26)
      ..lineTo(w * 0.88, h * 0.21)
      ..quadraticBezierTo(w * 0.94, h * 0.17, w, h * 0.29)
      ..lineTo(w, h * 0.55)
      ..lineTo(0, h * 0.55)
      ..close();

    canvas.drawPath(farMountainPath, Paint()..color = farMountainColor);

    // --- Mid-range Pine Ridge Mountains ---
    final midMountainColor = (isDark
            ? const Color(0xFF1E322D)
            : const Color(0xFFA1B8B2))
        .withValues(alpha: isDark ? 0.45 : 0.55);

    final midMountainPath = Path()
      ..moveTo(0, h * 0.47)
      ..lineTo(w * 0.15, h * 0.40)
      ..quadraticBezierTo(w * 0.25, h * 0.34, w * 0.33, h * 0.39)
      ..lineTo(w * 0.48, h * 0.32)
      ..quadraticBezierTo(w * 0.58, h * 0.27, w * 0.68, h * 0.35)
      ..lineTo(w * 0.82, h * 0.30)
      ..quadraticBezierTo(w * 0.92, h * 0.25, w, h * 0.37)
      ..lineTo(w, h * 0.58)
      ..lineTo(0, h * 0.58)
      ..close();

    canvas.drawPath(midMountainPath, Paint()..color = midMountainColor);

    // --- Atmospheric Lake Horizon & Reflection ---
    final waterColor = (isDark
            ? const Color(0xFF172825)
            : const Color(0xFFC7D7D3))
        .withValues(alpha: isDark ? 0.30 : 0.40);

    final waterRect = Rect.fromLTRB(0, h * 0.48, w, h * 0.75);
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterColor,
          waterColor.withValues(alpha: 0.05),
        ],
      ).createShader(waterRect);
    canvas.drawRect(waterRect, waterPaint);

    // --- Layered Fog and Mist Banks ---
    for (var i = 0; i < 4; i++) {
      final yPos = h * (0.33 + i * 0.07);
      final alpha = (isDark ? 0.08 : 0.14) - i * 0.02;
      if (alpha <= 0) continue;

      final fogPaint = Paint()
        ..color = (isDark ? Colors.white : const Color(0xFFF1F5F4))
            .withValues(alpha: alpha.clamp(0.01, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 28.0 + i * 10);

      final fogPath = Path()
        ..moveTo(-w * 0.1, yPos + h * 0.03)
        ..quadraticBezierTo(
            w * 0.25, yPos - h * 0.02, w * 0.45, yPos + h * 0.02)
        ..quadraticBezierTo(
            w * 0.65, yPos + h * 0.05, w * 0.85, yPos - h * 0.01)
        ..quadraticBezierTo(
            w * 0.98, yPos + h * 0.03, w * 1.15, yPos + h * 0.04)
        ..lineTo(w * 1.15, yPos + h * 0.10)
        ..lineTo(-w * 0.1, yPos + h * 0.10)
        ..close();

      canvas.drawPath(fogPath, fogPaint);
    }

    // --- Soft Billowing Clouds in the Upper Sky ---
    _paintCloud(
      canvas,
      Offset(w * 0.20, h * 0.09),
      w * 0.24,
      isDark ? 0.08 : 0.18,
    );
    _paintCloud(
      canvas,
      Offset(w * 0.75, h * 0.07),
      w * 0.22,
      isDark ? 0.07 : 0.16,
    );
    _paintCloud(
      canvas,
      Offset(w * 0.50, h * 0.14),
      w * 0.28,
      isDark ? 0.06 : 0.14,
    );
  }

  void _paintCloud(Canvas canvas, Offset center, double radius, double alpha) {
    final cloudColor = (isDark ? Colors.white : const Color(0xFFEDF3F1))
        .withValues(alpha: alpha);
    final paint = Paint()
      ..color = cloudColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.55);

    canvas.drawCircle(center, radius * 0.52, paint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.36, center.dy + radius * 0.08),
      radius * 0.40,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.36, center.dy + radius * 0.06),
      radius * 0.44,
      paint,
    );
  }

  @override
  bool shouldRepaint(_MindoraNaturePainter old) => old.isDark != isDark;
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

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
            BoxShadow(color: color, blurRadius: 100, spreadRadius: 36),
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
  final IconData? icon;
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
