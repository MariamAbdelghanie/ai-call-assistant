import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    // Turuncu zeminde koyu saat/pil simgeleri okunmuyor.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor:
          tokens.isDark ? AppPalette.darkSurface : AppPalette.accentDeep,
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
                            clipBehavior: Clip.antiAlias,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Kartin ustunde yapay zekayi anlatan
                                // lacivert gorsel band: referanstaki
                                // "form + gorsel" ikilisinin telefon
                                // genisligine sigan hali.
                                const _AiShowcase(),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 26, 24, 26),
                                  child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _register
                                        ? t.t('tabSignUp')
                                        : t.t('tabSignIn'),
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
                                      return RegExp(
                                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
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
                                      if (v.isEmpty)
                                        return t.t('fieldPassword');
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // --- Kartin altindaki guven satiri ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Zemin turuncu oldugu icin bu satir beyaz;
                              // gri ton okunmuyordu.
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: tokens.isDark
                                    ? tokens.muted
                                    : Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  t.t('dataSecure'),
                                  textAlign: TextAlign.center,
                                  style: text.labelSmall?.copyWith(
                                    color: tokens.isDark
                                        ? tokens.muted
                                        : Colors.white.withValues(alpha: 0.9),
                                  ),
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
      ),
    );
  }
}

/// Kartin ust bandi: lacivert zemin uzerinde sesin yapay zekaya
/// donusmesini anlatan bir cizim.
///
/// Fotograf yerine cizim kullaniyorum: fotograf hem telifli oluyor hem de
/// her ekran boyutunda bozuluyor; cizim vektorel oldugu icin her cozunurlukte
/// net kaliyor ve uygulamanin renkleriyle birebir uyuyor.
class _AiShowcase extends StatefulWidget {
  const _AiShowcase();

  @override
  State<_AiShowcase> createState() => _AiShowcaseState();
}

class _AiShowcaseState extends State<_AiShowcase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return SizedBox(
      height: 172,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.indigoDeep, AppPalette.indigo],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _AiScenePainter(progress: _controller.value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _BrandMark(size: 38, radius: 12),
                    const SizedBox(width: 11),
                    Text(
                      'CALLORA',
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  t.t('welcomeTagline'),
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lacivert bandin uzerindeki cizim: sagda bir ses dalgasindan cikip
/// dugumlere yayilan bir ag. Yavasca nefes alir, dikkat dagitmaz.
class _AiScenePainter extends CustomPainter {
  _AiScenePainter({required this.progress});

  /// 0..1 arasi donen sayac.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.78, size.height * 0.52);
    final pulse = 0.5 + 0.5 * math.sin(progress * 2 * math.pi);

    // Es merkezli halkalar: sesin yayilmasi.
    for (var i = 0; i < 4; i++) {
      final radius = 26.0 + i * 20 + pulse * 5;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.07 + 0.05 * (3 - i) / 3),
      );
    }

    // Turuncu cekirdek.
    canvas.drawCircle(
      center,
      20 + pulse * 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [AppPalette.orange, AppPalette.accentDeep],
        ).createShader(Rect.fromCircle(center: center, radius: 24)),
    );
    canvas.drawCircle(
      center,
      34 + pulse * 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppPalette.orange.withValues(alpha: 0.35),
    );

    // Cekirdegin icindeki ses cubuklari.
    const bars = [0.42, 0.74, 1.0, 0.66, 0.38];
    for (var i = 0; i < bars.length; i++) {
      final wobble =
          0.75 + 0.25 * math.sin(progress * 2 * math.pi * 2 + i * 0.9);
      final height = 16 * bars[i] * wobble;
      final x = center.dx - 12 + i * 6.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, center.dy), width: 2.6, height: height),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }

    // Soldaki dugum agi: sesin veriye donusmesi.
    final nodes = <Offset>[
      Offset(size.width * 0.10, size.height * 0.30),
      Offset(size.width * 0.20, size.height * 0.62),
      Offset(size.width * 0.33, size.height * 0.24),
      Offset(size.width * 0.38, size.height * 0.72),
      Offset(size.width * 0.50, size.height * 0.44),
    ];
    final link = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.16);
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        if ((nodes[i] - nodes[j]).distance > size.width * 0.26) continue;
        canvas.drawLine(nodes[i], nodes[j], link);
      }
      canvas.drawLine(nodes[i], center, link);
    }
    for (var i = 0; i < nodes.length; i++) {
      final glow = 0.5 + 0.5 * math.sin(progress * 2 * math.pi + i * 1.3);
      canvas.drawCircle(
        nodes[i],
        3 + glow * 1.4,
        Paint()
          ..color = (i.isEven ? AppPalette.orange : Colors.white)
              .withValues(alpha: 0.55 + 0.35 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_AiScenePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Zemin: cok yumusak iki leke, turuncu ve lacivert. Dikkat dagitmaz,
/// yuzeyin duz gri gorunmesini engeller.
/// Zemin: sicak turuncu bir gradyan uzerinde cok yumusak lekeler.
///
/// Kart beyaz oldugu icin zeminin de beyaz olmasi sayfayi bos gosteriyordu;
/// renkli zemin kartin havada durmasini saglar.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (tokens.isDark) return const SizedBox.shrink();
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF57A33),
            AppPalette.orange,
            AppPalette.accentDeep,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: CustomPaint(painter: _BackdropPainter()),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Iki genis isik lekesi: duz gradyanin plastik gorunmesini engeller.
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.12),
      size.width * 0.55,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.18, size.height * 0.12),
            radius: size.width * 0.55,
          ),
        ),
    );

    // Alt kosede lacivert bir golge: ucuncu renk burada da var, boylece
    // sayfa yalniz turuncu-beyazdan ibaret kalmiyor.
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.96),
      size.width * 0.7,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppPalette.indigoDeep.withValues(alpha: 0.38),
            AppPalette.indigoDeep.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.9, size.height * 0.96),
            radius: size.width * 0.7,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}

/// Marka isareti: lacivert kare icinde turuncu ses dalgasi.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 70, this.radius = 21});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.49,
          height: size * 0.37,
          child: const CustomPaint(painter: _WaveMarkPainter()),
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
