import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/assistant_robot.dart';
import '../widgets/glass.dart';

/// Acilis ekrani: robot selam verir, dokununca yukari dogru ucarak kaybolur.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  bool _leaving = false;

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
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
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _exit]),
            builder: (context, _) {
              // Cikista robot yukari suzulur, yazilar asagi kayar.
              final lift = reduceMotion ? 0.0 : exit.value;
              return Opacity(
                opacity: 1 - lift * 0.9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 12, 26, 34),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Transform.translate(
                        offset: Offset(0, -lift * 320),
                        child: Transform.scale(
                          scale: (reduceMotion ? 1.0 : enter.value)
                              .clamp(0.0, 1.0) *
                              (1 - lift * 0.25),
                          child: const AssistantRobot(
                            mood: RobotMood.idle,
                            size: 250,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Transform.translate(
                        offset: Offset(0, lift * 140),
                        child: Column(
                          children: [
                            Text(
                              strings.t('welcomeTitle'),
                              textAlign: TextAlign.center,
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              strings.t('welcomeSubtitle'),
                              textAlign: TextAlign.center,
                              style: context.text.bodyLarge
                                  ?.copyWith(color: tokens.muted, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      Transform.translate(
                        offset: Offset(0, lift * 200),
                        child: GradientButton(
                          label: strings.t('welcomeCta'),
                          icon: Icons.arrow_forward_rounded,
                          height: 58,
                          onTap: _takeOff,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        strings.t('welcomeHint'),
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall
                            ?.copyWith(color: tokens.muted),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
