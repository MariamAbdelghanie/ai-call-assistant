import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/soft_icon.dart';
import '../widgets/voice_orb.dart';

/// Acilis ekrani.
///
/// Tek bir gorsel odak var: siyah zeminde duran kure. Metin blogu kurenin
/// altinda hizalanir, eylem en altta tek basina durur. Robot karakteri yerine
/// kure kullanilir; boylece acilis, gorusme ekraniyla ayni kimligi tasir.
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
    duration: const Duration(milliseconds: 950),
  )..forward();

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  bool _leaving = false;
  bool _poked = false;

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _tapOrb() async {
    if (_leaving) return;
    setState(() => _poked = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted && !_leaving) setState(() => _poked = false);
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

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _exit]),
            builder: (context, _) {
              final lift = reduceMotion
                  ? 0.0
                  : Curves.easeInCubic.transform(_exit.value);

              return Opacity(
                opacity: 1 - lift * 0.95,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Rise(
                        animation: _enter,
                        delay: 0.0,
                        reduceMotion: reduceMotion,
                        child: const _BrandRow(),
                      ),

                      const Spacer(flex: 3),

                      // Kure: ekranin tek gorsel odagi.
                      Center(
                        child: _Rise(
                          animation: _enter,
                          delay: 0.10,
                          reduceMotion: reduceMotion,
                          child: Transform.translate(
                            offset: Offset(0, -lift * 220),
                            child: GestureDetector(
                              onTap: _tapOrb,
                              behavior: HitTestBehavior.opaque,
                              child: VoiceOrb(
                                size: 300,
                                speaking: _poked,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Metin solda hizali: ortalanmis blok sunum slaydi
                      // gibi duruyordu, sola hizalama daha urun gibi durur.
                      _Rise(
                        animation: _enter,
                        delay: 0.28,
                        reduceMotion: reduceMotion,
                        child: Transform.translate(
                          offset: Offset(0, lift * 110),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.t('welcomeHeadline'),
                                style: context.text.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.4,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                strings.t('welcomeSubtitle'),
                                style: context.text.bodyMedium?.copyWith(
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Ozellikler: ikon kutucugu yerine tek satirlik etiketler.
                      _Rise(
                        animation: _enter,
                        delay: 0.40,
                        reduceMotion: reduceMotion,
                        child: Transform.translate(
                          offset: Offset(0, lift * 140),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(
                                icon: AppIcon.phone,
                                label: strings.t('featureAnswer'),
                              ),
                              _Tag(
                                icon: AppIcon.inbox,
                                label: strings.t('featureNote'),
                              ),
                              _Tag(
                                icon: AppIcon.spark,
                                label: strings.t('featureSummary'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      _Rise(
                        animation: _enter,
                        delay: 0.52,
                        reduceMotion: reduceMotion,
                        child: Transform.translate(
                          offset: Offset(0, lift * 180),
                          child: _StartButton(
                            label: strings.t('welcomeCta'),
                            onTap: _takeOff,
                          ),
                        ),
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

/// Ust satir: kucuk bir isaret ve uygulama adi.
class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF3BE0FF), Color(0xFFFF4FD8)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          strings.t('appTitle').toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
            color: context.tokens.muted,
          ),
        ),
      ],
    );
  }
}

/// Tek satirlik ozellik etiketi.
class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final AppIcon icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 15, 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SoftIcon(icon, size: 15, color: const Color(0xFF3BE0FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

/// Tam genislikte, net bir eylem dugmesi.
class _StartButton extends StatelessWidget {
  const _StartButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: context.text.titleMedium?.copyWith(
                    color: const Color(0xFF05010A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                const SoftIcon(AppIcon.chevron,
                    size: 18, color: Color(0xFF05010A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icerigi sirayla asagidan yukari getirir.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.delay,
    required this.child,
    required this.reduceMotion,
  });

  final Animation<double> animation;
  final double delay;
  final Widget child;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    final v = Curves.easeOutCubic.transform(
      ((animation.value - delay) / (1 - delay)).clamp(0.0, 1.0),
    );
    return Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, (1 - v) * 22), child: child),
    );
  }
}
