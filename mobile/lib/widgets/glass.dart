import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pastel degradeli zemin. Tum ekranlar bunun uzerine kurulur.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mesh = context.tokens.mesh;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: mesh,
          stops: const [0.0, 0.38, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Kosedeki yumusak isik lekeleri derinlik hissi verir.
          Positioned(
            top: -90,
            right: -70,
            child: _Blob(
              color: AppPalette.blush.withValues(
                alpha: context.tokens.isDark ? 0.22 : 0.45,
              ),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Blob(
              color: AppPalette.brandLight.withValues(
                alpha: context.tokens.isDark ? 0.18 : 0.40,
              ),
              size: 300,
            ),
          ),
          child,
        ],
      ),
    );
  }
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

/// Degradeli zemin + saydam AppBar iceren ekran iskeleti.
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

/// Buzlu cam yuzey.
///
/// `blur` yalnizca one cikan birkac kart icin acilir; uzun listelerde
/// kaydirma akiciligini korumak adina bulaniklik olmadan kullanilir.
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

/// Degradeli, yuvarlak ana eylem dugmesi.
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

/// Bolum basligi: kucuk, aralikli ve sakin.
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

/// Uygulamanin kendi asistan simgesi: cam baloncuk icinde sade bir yuz.
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

/// Listelerde kartlarin sirayla, yumusakca belirmesini saglar.
///
/// `index` arttikca giris biraz gecikir; boylece ekran tek seferde degil
/// akis halinde dolar. Azaltilmis hareket ayarinda animasyon atlanir.
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
