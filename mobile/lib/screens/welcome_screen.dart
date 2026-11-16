import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/assistant_robot.dart';
import '../widgets/glass.dart';

/// Mindora-inspired Welcome & Onboarding Screen:
/// Features floating ethereal particles, interactive breathing agent core,
/// frosted glass container, and staggered spring animations.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Staggered entrance animation
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // Exit animation when user taps Start
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  // Breathing pulse for ambient glows
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  // Floating misty particles
  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  bool _leaving = false;

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    _breathe.dispose();
    _particles.dispose();
    super.dispose();
  }

  Future<void> _takeOff() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await _exit.forward();
    if (mounted) widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final enter = CurvedAnimation(parent: _enter, curve: Curves.easeOutBack);
    final exit = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Floating ambient mist particles
              if (!reduceMotion)
                AnimatedBuilder(
                  animation: _particles,
                  builder: (context, _) => Positioned.fill(
                    child: CustomPaint(
                      painter: _MindoraParticlePainter(
                        t: _particles.value,
                        isDark: tokens.isDark,
                      ),
                    ),
                  ),
                ),

              // Main Onboarding Layout
              AnimatedBuilder(
                animation: Listenable.merge([_enter, _exit, _breathe]),
                builder: (context, _) {
                  final lift = reduceMotion ? 0.0 : exit.value;
                  final breatheVal = reduceMotion ? 0.5 : _breathe.value;

                  return Opacity(
                    opacity: (1 - lift * 0.95).clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Central Mindora Zen Agent with breathing aura
                          Transform.translate(
                            offset: Offset(0, -lift * 340),
                            child: Transform.scale(
                              scale: (reduceMotion ? 1.0 : enter.value).clamp(0.0, 1.0) *
                                  (1 - lift * 0.20),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Breathing multi-ring aura
                                  Container(
                                    width: 280 + breatheVal * 28,
                                    height: 280 + breatheVal * 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppPalette.sage.withValues(
                                            alpha: 0.12 + breatheVal * 0.12,
                                          ),
                                          blurRadius: 70 + breatheVal * 24,
                                          spreadRadius: 12 + breatheVal * 12,
                                        ),
                                        BoxShadow(
                                          color: AppPalette.mistBlue.withValues(
                                            alpha: 0.10 + breatheVal * 0.10,
                                          ),
                                          blurRadius: 50 + breatheVal * 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // The newly styled Mindora AI Agent
                                  const AssistantRobot(
                                    mood: RobotMood.idle,
                                    size: 260,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Frosted Glass Content Panel
                          Transform.translate(
                            offset: Offset(0, lift * 180),
                            child: GlassCard(
                              blur: true,
                              strong: true,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                              radius: AppTheme.radius,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Top Mindora Pill Badge
                                  _StaggeredItem(
                                    animation: enter,
                                    delay: 0.15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppPalette.sage.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: AppPalette.sage.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: AppPalette.sage,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'MINDORA • AI ASSISTANT',
                                            style: context.text.labelSmall?.copyWith(
                                              color: AppPalette.sage,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Headline
                                  _StaggeredItem(
                                    animation: enter,
                                    delay: 0.30,
                                    child: Text(
                                      strings.t('welcomeTitle'),
                                      textAlign: TextAlign.center,
                                      style: context.text.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Subtitle
                                  _StaggeredItem(
                                    animation: enter,
                                    delay: 0.45,
                                    child: Text(
                                      strings.t('welcomeSubtitle'),
                                      textAlign: TextAlign.center,
                                      style: context.text.bodyMedium?.copyWith(
                                        color: tokens.muted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Shimmering Start Button (Blended 4-color gradient)
                                  _StaggeredItem(
                                    animation: enter,
                                    delay: 0.60,
                                    child: GradientButton(
                                      label: strings.t('welcomeCta'),
                                      icon: Icons.arrow_forward_rounded,
                                      height: 56,
                                      useFourColors: true,
                                      onTap: _takeOff,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Bottom Hint
                                  _StaggeredItem(
                                    animation: enter,
                                    delay: 0.70,
                                    child: Text(
                                      strings.t('welcomeHint'),
                                      textAlign: TextAlign.center,
                                      style: context.text.labelSmall?.copyWith(
                                        color: tokens.muted,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper for staggered animated entrance.
class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({
    required this.animation,
    required this.delay,
    required this.child,
  });

  final Animation<double> animation;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = ((animation.value - delay) / (1.0 - delay)).clamp(0.0, 1.0);
    final curved = Curves.easeOutCubic.transform(t);

    return Opacity(
      opacity: curved,
      child: Transform.translate(
        offset: Offset(0, (1 - curved) * 24),
        child: child,
      ),
    );
  }
}

/// Floating particles resembling fireflies / mist orbs in the serene landscape.
class _MindoraParticlePainter extends CustomPainter {
  _MindoraParticlePainter({required this.t, required this.isDark});

  final double t;
  final bool isDark;

  static final List<_MistParticle> _particles = List.generate(16, (i) {
    final rng = math.Random(i * 37 + 11);
    return _MistParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 2.2 + rng.nextDouble() * 3.8,
      speed: 0.4 + rng.nextDouble() * 0.8,
      phase: rng.nextDouble() * math.pi * 2,
      colorType: i % 4,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final angle = t * math.pi * 2 * p.speed + p.phase;
      final dx = p.x * size.width + math.sin(angle) * 16;
      final dy = p.y * size.height + math.cos(angle * 0.8) * 12;
      final pulse = (math.sin(angle * 1.6) * 0.5 + 0.5);

      final color = switch (p.colorType) {
        0 => AppPalette.sage,
        1 => AppPalette.mistBlue,
        2 => AppPalette.blush,
        _ => AppPalette.mistWhite,
      };

      final alpha = (isDark ? 0.14 : 0.22) + pulse * 0.12;

      canvas.drawCircle(
        Offset(dx, dy),
        p.radius + pulse * 1.8,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 1.6 + pulse * 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(_MindoraParticlePainter old) => old.t != t;
}

class _MistParticle {
  const _MistParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.colorType,
  });

  final double x, y, radius, speed, phase;
  final int colorType;
}
