import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_icon.dart';

/// Uygulamanin zemini: duz, notr ve sakin bir yuzey.
///
/// Onceki surumde burada neon haleler ciziliyordu. Acik temali is
/// uygulamasinda bu dikkat dagitiyor; zemin artik yalnizca cok hafif bir
/// dikey gecis. Tum ekranlar bunun uzerine binmeye devam eder.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.tokens.mesh,
          stops: const [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: child,
    );
  }
}

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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (strong ? tokens.glassStrong : tokens.glass)
            : null,
        gradient: gradient,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? tokens.glassBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
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

    final gradient =
        useFourColors ? tokens.fourColorGradient : tokens.brandGradient;

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: [
              BoxShadow(
                color: AppPalette.accent.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalette.accentSoft,
      ),
      child: Center(
        child: Icon(
          Icons.support_agent_rounded,
          size: size * 0.55,
          color: AppPalette.accent,
        ),
      ),
    );
  }
}

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
