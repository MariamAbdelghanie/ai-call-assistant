import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/assistant_robot.dart';
import '../widgets/glass.dart';

/// Opening screen: the robot greets, then flies away when tapped.
/// Mindora-inspired with floating particles, staggered animations,
/// and a soft breathing glow.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // Staggered entrance controllers
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  // Continuous breathing / glow loop
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  // Floating particles loop
  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
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
              // Floating nature particles
              if (!reduceMotion)
                AnimatedBuilder(
                  animation: _particles,
                  builder: (context, _) => CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: _ParticlePainter(
                      t: _particles.value,
                      isDark: tokens.isDark,
                    ),
                  ),
                ),

              // Main content
              AnimatedBuilder(
                animation: Listenable.merge([_enter, _exit, _breathe]),
                builder: (context, _) {
                  final lift = reduceMotion ? 0.0 : exit.value;
                  final breatheVal =
                      reduceMotion ? 0.0 : _breathe.value;

                  return Opacity(
                    opacity: 1 - lift * 0.9,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 12, 26, 34),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Robot with breathing glow
                          Transform.translate(
                            offset: Offset(0, -lift * 320),
                            child: Transform.scale(
                              scale: (reduceMotion ? 1.0 : enter.value)
                                      .clamp(0.0, 1.0) *
                                  (1 - lift * 0.25),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Breathing glow ring
                                  Container(
                                    width: 280 + breatheVal * 20,
                                    height: 280 + breatheVal * 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppPalette.brand.withValues(
                                            alpha: 0.08 + breatheVal * 0.08,
                                          ),
                                          blurRadius: 60 + breatheVal * 20,
                                          spreadRadius: 10 + breatheVal * 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const AssistantRobot(
                                    mood: RobotMood.idle,
                                    size: 250,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Title with staggered entrance
                          Transform.translate(
                            offset: Offset(0, lift * 140),
                            child: Column(
                              children: [
                                // Title slides in from bottom with delay
                                _StaggeredFade(
                                  animation: enter,
                                  delay: 0.2,
                                  slideOffset: 0.15,
                                  child: Text(
                                    strings.t('welcomeTitle'),
                                    textAlign: TextAlign.center,
                                    style:
                                        context.text.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Subtitle slides in later
                                _StaggeredFade(
                                  animation: enter,
                                  delay: 0.35,
                                  slideOffset: 0.12,
                                  child: Text(
                                    strings.t('welcomeSubtitle'),
                                    textAlign: TextAlign.center,
                                    style: context.text.bodyLarge?.copyWith(
                                      color: tokens.muted,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 34),

                          // CTA button with staggered entrance
                          Transform.translate(
                            offset: Offset(0, lift * 200),
                            child: _StaggeredFade(
                              animation: enter,
                              delay: 0.50,
                              slideOffset: 0.10,
                              child: GradientButton(
                                label: strings.t('welcomeCta'),
                                icon: Icons.arrow_forward_rounded,
                                height: 58,
                                onTap: _takeOff,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Hint text
                          _StaggeredFade(
                            animation: enter,
                            delay: 0.60,
                            slideOffset: 0.08,
                            child: Text(
                              strings.t('welcomeHint'),
                              textAlign: TextAlign.center,
                              style: context.text.labelSmall
                                  ?.copyWith(color: tokens.muted),
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

/// Staggered fade+slide widget for entrance animations.
class _StaggeredFade extends StatelessWidget {
  const _StaggeredFade({
    required this.animation,
    required this.delay,
    required this.slideOffset,
    required this.child,
  });

  final Animation<double> animation;
  final double delay;
  final double slideOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Map the animation value with a delay so each element starts later
    final t = ((animation.value - delay) / (1 - delay)).clamp(0.0, 1.0);
    final curved = Curves.easeOutCubic.transform(t);

    return Opacity(
      opacity: curved,
      child: Transform.translate(
        offset: Offset(0, (1 - curved) * 30 * slideOffset / 0.15),
        child: child,
      ),
    );
  }
}

/// Paints floating soft particles/orbs reminiscent of fireflies in mist.
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.t, required this.isDark});

  final double t;
  final bool isDark;

  static final List<_Particle> _orbs = List.generate(14, (i) {
    final rng = math.Random(i * 42 + 7);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      radius: 2.0 + rng.nextDouble() * 4.0,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
      colorIndex: rng.nextInt(4),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final orb in _orbs) {
      final angle = t * math.pi * 2 * orb.speed + orb.phase;
      final dx = orb.x * size.width + math.sin(angle) * 18;
      final dy = orb.y * size.height + math.cos(angle * 0.7) * 12;
      final pulse = (math.sin(angle * 1.5) * 0.5 + 0.5);

      final color = switch (orb.colorIndex) {
        0 => AppPalette.brand,
        1 => AppPalette.cyan,
        2 => AppPalette.blush,
        _ => AppPalette.lilac,
      };

      final alpha = (isDark ? 0.12 : 0.18) + pulse * 0.1;

      canvas.drawCircle(
        Offset(dx, dy),
        orb.radius + pulse * 2,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, orb.radius * 1.5 + pulse * 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.colorIndex,
  });

  final double x, y, radius, speed, phase;
  final int colorIndex;
}
