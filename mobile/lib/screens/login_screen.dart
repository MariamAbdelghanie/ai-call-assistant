import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Oturum ekrani: e-posta ile giris/kayit ve Google ile giris.
///
/// Sahte giris yoktur. Parola uygulamanin veritabanina hic yazilmaz;
/// Firebase Authentication parolayi kendi tarafinda ozetleyerek saklar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _register = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    if (_register) {
      await widget.auth.registerWithEmail(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
    } else {
      await widget.auth.signInWithEmail(
        email: _email.text,
        password: _password.text,
      );
    }
  }

  Future<void> _resetPassword() async {
    final t = AppStrings.of(context);
    final valid =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());
    if (!valid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.t('errEmailRequired'))));
      return;
    }
    final sent = await widget.auth.sendPasswordReset(_email.text);
    if (!mounted || !sent) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t.t('resetSent'))));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tokens = context.tokens;
    final text = context.text;
    final auth = widget.auth;

    return Scaffold(
      backgroundColor: tokens.isDark ? null : AppPalette.surfaceAlt,
      body: Stack(
        children: [
          const Positioned.fill(child: _Backdrop()),
          SafeArea(
        child: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Form karti ---
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                        decoration: BoxDecoration(
                          color: tokens.isDark
                              ? tokens.glass
                              : AppPalette.surface,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: tokens.isDark
                                ? tokens.glassBorder
                                : Colors.white,
                          ),
                          // Iki katman: genis ve cok yumusak olan derinligi,
                          // dar olan kenari tanimlar.
                          boxShadow: tokens.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppPalette.ink
                                        .withValues(alpha: 0.13),
                                    blurRadius: 48,
                                    spreadRadius: -6,
                                    offset: const Offset(0, 26),
                                  ),
                                  BoxShadow(
                                    color: AppPalette.ink
                                        .withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Center(child: _BrandMark()),
                              const SizedBox(height: 18),
                              Text(
                                _register ? t.t('tabSignUp') : t.t('tabSignIn'),
                                textAlign: TextAlign.center,
                                style: text.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.t('loginSubtitle'),
                                textAlign: TextAlign.center,
                                style: text.bodySmall
                                    ?.copyWith(color: tokens.muted),
                              ),
                              const SizedBox(height: 26),
                              if (auth.errorKey != null) ...[
                                _ErrorBanner(auth: auth),
                                const SizedBox(height: 18),
                              ],
                              if (_register) ...[
                                _Field(
                                  label: t.t('fieldName'),
                                  controller: _name,
                                  icon: Icons.person_outline,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                              ],
                              _Field(
                                label: t.t('fieldEmail'),
                                controller: _email,
                                icon: Icons.mail_outline,
                                hint: 'ornek@eposta.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: (value) {
                                  final v = (value ?? '').trim();
                                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(v)
                                      ? null
                                      : t.t('errEmailRequired');
                                },
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: t.t('fieldPassword'),
                                controller: _password,
                                icon: Icons.lock_outline,
                                hint: '••••••••',
                                obscure: _obscure,
                                textInputAction: _register
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                  ),
                                  color: tokens.muted,
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                validator: (value) {
                                  final v = value ?? '';
                                  if (v.isEmpty) return t.t('fieldPassword');
                                  if (_register &&
                                      !PasswordPolicy.isValid(v)) {
                                    return t.t('authWeakPassword');
                                  }
                                  return null;
                                },
                              ),
                              if (_register) ...[
                                const SizedBox(height: 12),
                                _PasswordMeter(value: _password.text),
                                const SizedBox(height: 16),
                                _Field(
                                  label: t.t('fieldPasswordConfirm'),
                                  controller: _confirm,
                                  icon: Icons.lock_outline,
                                  hint: '••••••••',
                                  obscure: _obscure,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) =>
                                      (value ?? '') == _password.text
                                          ? null
                                          : t.t('errPasswordMismatch'),
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: GestureDetector(
                                    onTap:
                                        auth.isBusy ? null : _resetPassword,
                                    child: Text(
                                      '${t.t('forgotPassword')}?',
                                      style: text.labelLarge?.copyWith(
                                        color: AppPalette.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: auth.isBusy ? null : _submit,
                                  child: auth.isBusy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(_register
                                                ? t.t('tabSignUp')
                                                : t.t('tabSignIn')),
                                            const SizedBox(width: 10),
                                            const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _OrDivider(label: t.t('orContinueWith')),
                              const SizedBox(height: 18),
                              _GoogleButton(
                                busy: auth.isBusy,
                                onTap: auth.isBusy
                                    ? null
                                    : () => auth.signInWithGoogle(),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: auth.isBusy
                                      ? null
                                      : () => setState(() {
                                            _register = !_register;
                                            auth.errorKey = null;
                                          }),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppPalette.ink,
                                    side: const BorderSide(
                                        color: AppPalette.ink, width: 1.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm),
                                    ),
                                  ),
                                  child: Text(
                                    _register
                                        ? t.t('tabSignIn')
                                        : t.t('tabSignUp'),
                                    style: text.labelLarge
                                        ?.copyWith(fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // --- Kartin altindaki guven satiri ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 14, color: tokens.muted),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              t.t('dataSecure'),
                              textAlign: TextAlign.center,
                              style: text.labelSmall
                                  ?.copyWith(color: tokens.muted),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
        ],
      ),
    );
  }
}

/// Zemin: cok yumusak iki leke, turuncu ve lacivert. Dikkat dagitmaz,
/// yuzeyin duz gri gorunmesini engeller.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (tokens.isDark) return const SizedBox.shrink();
    return CustomPaint(painter: _BackdropPainter());
  }
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _blobs(canvas, size);
    _network(canvas, size);
    _arcs(canvas, size);
  }

  /// Yumusak renk lekeleri: yuzeyin duz gri gorunmesini engeller.
  void _blobs(Canvas canvas, Size size) {
    void blob(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    blob(Offset(size.width * 0.10, size.height * 0.04), size.width * 0.75,
        AppPalette.orange.withValues(alpha: 0.16));
    blob(Offset(size.width * 0.98, size.height * 0.26), size.width * 0.60,
        AppPalette.ink.withValues(alpha: 0.09));
    blob(Offset(size.width * 0.02, size.height * 0.98), size.width * 0.65,
        AppPalette.ink.withValues(alpha: 0.06));
  }

  /// Soluk bir dugum agi: yapay zekayi cagristirir, okumayi zorlastirmaz.
  /// Dugumler sabit oranlarla yerlestirilir; her karede ayni gorunur.
  void _network(Canvas canvas, Size size) {
    const points = <Offset>[
      Offset(0.08, 0.13), Offset(0.26, 0.07), Offset(0.42, 0.17),
      Offset(0.18, 0.26), Offset(0.34, 0.31), Offset(0.06, 0.37),
      Offset(0.88, 0.62), Offset(0.72, 0.70), Offset(0.94, 0.78),
      Offset(0.78, 0.86), Offset(0.60, 0.80), Offset(0.92, 0.92),
    ];
    const links = <List<int>>[
      [0, 1], [1, 2], [0, 3], [3, 4], [2, 4], [3, 5], [4, 5],
      [6, 7], [7, 8], [8, 9], [9, 10], [7, 10], [8, 11], [9, 11],
    ];

    Offset at(int i) =>
        Offset(points[i].dx * size.width, points[i].dy * size.height);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppPalette.ink.withValues(alpha: 0.10);
    for (final link in links) {
      canvas.drawLine(at(link[0]), at(link[1]), line);
    }

    for (var i = 0; i < points.length; i++) {
      final center = at(i);
      final isAccent = i % 4 == 0;
      canvas.drawCircle(
        center,
        isAccent ? 4.5 : 3,
        Paint()
          ..color = (isAccent ? AppPalette.orange : AppPalette.ink)
              .withValues(alpha: isAccent ? 0.26 : 0.16),
      );
      if (isAccent) {
        canvas.drawCircle(
          center,
          10,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = AppPalette.orange.withValues(alpha: 0.16),
        );
      }
    }
  }

  /// Ses dalgasini animsatan genis, cok soluk yaylar.
  void _arcs(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        size.width * (0.55 + i * 0.22),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppPalette.ink.withValues(alpha: 0.05),
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}

/// Marka isareti: lacivert kare icinde turuncu ses dalgasi.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 34,
          height: 26,
          child: CustomPaint(painter: _WaveMarkPainter()),
        ),
      ),
    );
  }
}

class _WaveMarkPainter extends CustomPainter {
  const _WaveMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Bes dikey cubuk: ortadakiler uzun, kenardakiler kisa.
    const heights = <double>[0.38, 0.70, 1.0, 0.70, 0.38];
    final barWidth = size.width / 9;
    for (var i = 0; i < heights.length; i++) {
      final h = size.height * heights[i];
      final x = (size.width / heights.length) * i + barWidth;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, barWidth, h),
        Radius.circular(barWidth),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = i == 2 ? AppPalette.orange : const Color(0xFFFFB183),
      );
    }
  }

  @override
  bool shouldRepaint(_WaveMarkPainter oldDelegate) => false;
}

/// Google ile devam et dugmesi.
///
/// Resmi Google logosu Google'in marka varligidir; depoya eklenmemistir.
/// assets/google_logo.png konulursa otomatik kullanilir, yoksa notr bir
/// ikon gosterilir. Logoyu Google'in marka sayfasindan indirip
/// pubspec.yaml icindeki assets listesine eklemek yeterlidir.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: tokens.isDark ? tokens.glass : AppPalette.surface,
          side: BorderSide(color: tokens.glassBorder, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Image.asset(
                'assets/google_logo.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.g_mobiledata_rounded,
                  size: 26,
                  color: context.scheme.onSurface,
                ),
              ),
            const SizedBox(width: 10),
            Text(
              AppStrings.of(context).t('loginGoogle'),
              style: context.text.labelLarge?.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ustunde etiketi olan giris alani.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: tokens.muted),
            suffixIcon: suffix,
            filled: true,
            fillColor: tokens.isDark ? tokens.glass : AppPalette.surfaceAlt,
          ),
        ),
      ],
    );
  }
}

/// Parola gucu cubugu ve karsilanmayan kurallar.
class _PasswordMeter extends StatelessWidget {
  const _PasswordMeter({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tokens = context.tokens;
    final strength = PasswordPolicy.strength(value);
    final missing = PasswordPolicy.violations(value);

    final Color color;
    final String label;
    if (strength >= 0.85) {
      color = tokens.success;
      label = t.t('pwStrong');
    } else if (strength >= 0.5) {
      color = tokens.pending;
      label = t.t('pwMedium');
    } else {
      color = tokens.urgent;
      label = t.t('pwWeak');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value.isEmpty ? 0 : strength,
                  minHeight: 5,
                  backgroundColor: tokens.glassBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value.isEmpty ? t.t('pwStrength') : label,
              style: context.text.labelSmall?.copyWith(
                color: value.isEmpty ? tokens.muted : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              for (final key in missing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_circle_outline,
                        size: 12, color: tokens.muted),
                    const SizedBox(width: 4),
                    Text(t.t(key),
                        style: context.text.labelSmall
                            ?.copyWith(color: tokens.muted)),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(child: Divider(color: tokens.glassBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label,
              style: context.text.bodySmall?.copyWith(color: tokens.muted)),
        ),
        Expanded(child: Divider(color: tokens.glassBorder)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final tokens = context.tokens;
    final key = auth.errorKey!;
    final isInfo = key == 'authCancelled';
    final color = isInfo ? tokens.pending : tokens.urgent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isInfo ? tokens.pendingSoft : tokens.urgentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isInfo ? Icons.info_outline : Icons.error_outline,
              size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.t(key),
              style: context.text.bodySmall?.copyWith(
                color: context.scheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
