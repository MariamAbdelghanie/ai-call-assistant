import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Karsilama + oturum baslatma ekrani.
///
/// Arastirilmis kalibi izler: tek bir deger ekrani (ozellik karuseli degil),
/// once sosyal giris, sonra e-posta yolu. Hesap neden gerekiyor sorusu
/// ekranda yanitlanir, cunku cagri kayitlari kisisel veridir.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStart,
    required this.auth,
  });

  /// E-posta akisina gecis.
  final VoidCallback onStart;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tokens = context.tokens;
    final text = context.text;

    return Scaffold(
      backgroundColor: tokens.isDark ? null : AppPalette.surface,
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          return Column(
            children: [
              const Expanded(flex: 5, child: _Hero()),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.t('welcomeTitle'),
                        textAlign: TextAlign.center,
                        style: text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.t('welcomeSubtitle'),
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: tokens.muted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: auth.isBusy
                              ? null
                              : () => auth.signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: tokens.isDark
                                ? tokens.glass
                                : AppPalette.surface,
                            side: BorderSide(color: tokens.glassBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (auth.isBusy)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(Icons.account_circle_outlined,
                                    size: 21, color: context.scheme.onSurface),
                              const SizedBox(width: 10),
                              Text(t.t('loginGoogle'),
                                  style:
                                      text.labelLarge?.copyWith(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: auth.isBusy ? null : onStart,
                        child: Text(t.t('welcomeEmailCta')),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t.t('welcomeHaveAccount'),
                              style: text.bodySmall
                                  ?.copyWith(color: tokens.muted)),
                          TextButton(
                            onPressed: auth.isBusy ? null : onStart,
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(t.t('welcomeSignIn')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 13, color: tokens.muted),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                t.t('loginWhyBody'),
                                textAlign: TextAlign.center,
                                style: text.labelSmall?.copyWith(
                                  color: tokens.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Ust gorsel: yumusak yesil zemin, asistan rozeti ve ozellik baloncuklari.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tokens.isDark
              ? const [Color(0xFF1B2026), Color(0xFF15181C)]
              : const [AppPalette.orangeSoft, Color(0xFFFFFFFF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RipplePainter(
                  color: AppPalette.orange
                      .withValues(alpha: tokens.isDark ? 0.16 : 0.22),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppPalette.accent,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.orange.withValues(alpha: 0.26),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 18),
                Text(
                  'CALLORA',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.0,
                    color: tokens.isDark
                        ? AppPalette.sageLight
                        : AppPalette.lightText,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                        icon: Icons.phone_in_talk_outlined,
                        label: t.t('featureAnswer')),
                    _Pill(
                        icon: Icons.edit_note_outlined,
                        label: t.t('featureNote')),
                    _Pill(
                        icon: Icons.summarize_outlined,
                        label: t.t('featureSummary')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.glass : AppPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.glassBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppPalette.accent),
          const SizedBox(width: 7),
          Text(label,
              style: context.text.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    for (var i = 1; i <= 5; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = color.withValues(alpha: color.a * (1 - i * 0.17));
      canvas.drawCircle(center, 62.0 + i * 34, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => oldDelegate.color != color;
}
