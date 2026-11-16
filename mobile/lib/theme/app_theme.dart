import 'package:flutter/material.dart';

/// Gorsel kimlik: gece mavisi-mor zemin, canli indigo vurgu.
/// Sesli asistan urunu icin sakin ama teknolojik bir his hedeflenir.
class AppPalette {
  // Marka
  static const Color brand = Color(0xFF7C6CF6);
  static const Color brandSoft = Color(0xFFA78BFA);
  static const Color brandDeep = Color(0xFF5B4BE0);

  // Durum
  static const Color urgent = Color(0xFFFF4D6D);
  static const Color pending = Color(0xFFFFB020);
  static const Color success = Color(0xFF22C55E);

  // Koyu tema
  static const Color darkBg = Color(0xFF0A0A12);
  static const Color darkSurface = Color(0xFF15151F);
  static const Color darkRaised = Color(0xFF1C1C28);
  static const Color darkBorder = Color(0xFF272738);
  static const Color darkText = Color(0xFFF4F4F8);
  static const Color darkMuted = Color(0xFF8B8BA3);

  // Acik tema
  static const Color lightBg = Color(0xFFF6F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightRaised = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E6F0);
  static const Color lightText = Color(0xFF14141E);
  static const Color lightMuted = Color(0xFF63637C);
}

/// Tema uzantisi: durum renkleri, yumusak zeminler ve marka gradyani.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.urgent,
    required this.urgentSoft,
    required this.pending,
    required this.pendingSoft,
    required this.success,
    required this.successSoft,
    required this.muted,
    required this.border,
    required this.raised,
    required this.brandSoft,
    required this.glow,
  });

  final Color urgent;
  final Color urgentSoft;
  final Color pending;
  final Color pendingSoft;
  final Color success;
  final Color successSoft;
  final Color muted;
  final Color border;
  final Color raised;
  final Color brandSoft;
  final Color glow;

  static const AppTokens dark = AppTokens(
    urgent: AppPalette.urgent,
    urgentSoft: Color(0xFF2C1520),
    pending: AppPalette.pending,
    pendingSoft: Color(0xFF2C2113),
    success: AppPalette.success,
    successSoft: Color(0xFF132A1E),
    muted: AppPalette.darkMuted,
    border: AppPalette.darkBorder,
    raised: AppPalette.darkRaised,
    brandSoft: Color(0xFF1E1B34),
    glow: Color(0x667C6CF6),
  );

  static const AppTokens light = AppTokens(
    urgent: Color(0xFFE11D48),
    urgentSoft: Color(0xFFFFE9ED),
    pending: Color(0xFFB45309),
    pendingSoft: Color(0xFFFFF2DC),
    success: Color(0xFF15803D),
    successSoft: Color(0xFFE4F7EB),
    muted: AppPalette.lightMuted,
    border: AppPalette.lightBorder,
    raised: AppPalette.lightRaised,
    brandSoft: Color(0xFFEFEDFE),
    glow: Color(0x335B4BE0),
  );

  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppPalette.brandDeep, AppPalette.brand, AppPalette.brandSoft],
      );

  @override
  AppTokens copyWith({
    Color? urgent,
    Color? urgentSoft,
    Color? pending,
    Color? pendingSoft,
    Color? success,
    Color? successSoft,
    Color? muted,
    Color? border,
    Color? raised,
    Color? brandSoft,
    Color? glow,
  }) =>
      AppTokens(
        urgent: urgent ?? this.urgent,
        urgentSoft: urgentSoft ?? this.urgentSoft,
        pending: pending ?? this.pending,
        pendingSoft: pendingSoft ?? this.pendingSoft,
        success: success ?? this.success,
        successSoft: successSoft ?? this.successSoft,
        muted: muted ?? this.muted,
        border: border ?? this.border,
        raised: raised ?? this.raised,
        brandSoft: brandSoft ?? this.brandSoft,
        glow: glow ?? this.glow,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentSoft: Color.lerp(urgentSoft, other.urgentSoft, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      pendingSoft: Color.lerp(pendingSoft, other.pendingSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.dark;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  static const double radius = 22;
  static const double radiusSm = 14;
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppPalette.darkBg,
        surface: AppPalette.darkSurface,
        onSurface: AppPalette.darkText,
        primary: AppPalette.brand,
        onPrimary: Colors.white,
        tokens: AppTokens.dark,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppPalette.lightBg,
        surface: AppPalette.lightSurface,
        onSurface: AppPalette.lightText,
        primary: AppPalette.brandDeep,
        onPrimary: Colors.white,
        tokens: AppTokens.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color primary,
    required Color onPrimary,
    required AppTokens tokens,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.brand,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppPalette.brandSoft,
      surface: surface,
      onSurface: onSurface,
      error: tokens.urgent,
      onError: Colors.white,
      outlineVariant: tokens.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    final textTheme = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: tokens.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: tokens.border),
        shape: const StadiumBorder(),
        backgroundColor: tokens.raised,
        selectedColor: primary,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.raised,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? AppPalette.darkSurface
            : AppPalette.lightSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.brandSoft,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
