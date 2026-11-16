import 'package:flutter/material.dart';

/// Gorsel kimlik: pastel degradeli zemin uzerinde buzlu cam yuzeyler.
class AppPalette {
  // Marka
  static const Color brand = Color(0xFF8B7BF0);
  static const Color brandDeep = Color(0xFF6C5CE0);
  static const Color pink = Color(0xFFFF9EC4);
  static const Color mint = Color(0xFF5FD6B0);
  static const Color peach = Color(0xFFFFB38A);

  // Durum
  static const Color urgent = Color(0xFFF2567C);
  static const Color pending = Color(0xFFE08A2B);
  static const Color success = Color(0xFF2FA37A);

  // Acik tema zemin duraklari
  static const List<Color> lightMesh = [
    Color(0xFFD6F5EA),
    Color(0xFFE7DCFF),
    Color(0xFFFFD9E8),
    Color(0xFFFFE6D2),
  ];

  // Koyu tema zemin duraklari
  static const List<Color> darkMesh = [
    Color(0xFF13202A),
    Color(0xFF221B3A),
    Color(0xFF2E1B2E),
    Color(0xFF1B1726),
  ];

  static const Color lightText = Color(0xFF2A2340);
  static const Color lightMuted = Color(0xFF6B6283);
  static const Color darkText = Color(0xFFF2EEFF);
  static const Color darkMuted = Color(0xFF9E96BC);
}

/// Cam yuzeyler ve durum renkleri icin tema uzantisi.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.mesh,
    required this.glass,
    required this.glassStrong,
    required this.glassBorder,
    required this.muted,
    required this.urgent,
    required this.urgentSoft,
    required this.pending,
    required this.pendingSoft,
    required this.success,
    required this.successSoft,
    required this.shadow,
    required this.isDark,
  });

  final List<Color> mesh;
  final Color glass;
  final Color glassStrong;
  final Color glassBorder;
  final Color muted;
  final Color urgent;
  final Color urgentSoft;
  final Color pending;
  final Color pendingSoft;
  final Color success;
  final Color successSoft;
  final Color shadow;
  final bool isDark;

  static const AppTokens light = AppTokens(
    mesh: AppPalette.lightMesh,
    glass: Color(0x8CFFFFFF),
    glassStrong: Color(0xCCFFFFFF),
    glassBorder: Color(0x99FFFFFF),
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0x26F2567C),
    pending: AppPalette.pending,
    pendingSoft: Color(0x26E08A2B),
    success: AppPalette.success,
    successSoft: Color(0x262FA37A),
    shadow: Color(0x1A5B4BA0),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: Color(0x14FFFFFF),
    glassStrong: Color(0x24FFFFFF),
    glassBorder: Color(0x2EFFFFFF),
    muted: AppPalette.darkMuted,
    urgent: Color(0xFFFF7E9D),
    urgentSoft: Color(0x33FF7E9D),
    pending: Color(0xFFFFC46B),
    pendingSoft: Color(0x33FFC46B),
    success: Color(0xFF5FD6B0),
    successSoft: Color(0x335FD6B0),
    shadow: Color(0x66000000),
    isDark: true,
  );

  /// Dugme ve vurgular icin marka degradesi.
  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppPalette.pink, AppPalette.brand],
      );

  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.pink.withValues(alpha: isDark ? 0.30 : 0.42),
          AppPalette.brand.withValues(alpha: isDark ? 0.28 : 0.34),
        ],
      );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) =>
      other is AppTokens && t > 0.5 ? other : this;
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  static const double radius = 26;
  static const double radiusSm = 18;
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        onSurface: AppPalette.lightText,
        tokens: AppTokens.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        onSurface: AppPalette.darkText,
        tokens: AppTokens.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color onSurface,
    required AppTokens tokens,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.brand,
      brightness: brightness,
    ).copyWith(
      primary: brightness == Brightness.dark
          ? AppPalette.brand
          : AppPalette.brandDeep,
      onPrimary: Colors.white,
      secondary: AppPalette.pink,
      surface: Colors.transparent,
      onSurface: onSurface,
      error: tokens.urgent,
      onError: Colors.white,
      outlineVariant: tokens.glassBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Zemin degradesi GlassScaffold tarafindan cizilir.
      scaffoldBackgroundColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    final textTheme = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.15,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: onSurface,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: tokens.glassBorder),
        shape: const StadiumBorder(),
        backgroundColor: tokens.glass,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.glass,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: tokens.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: tokens.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: BorderSide(color: tokens.glassBorder),
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.glassStrong,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.glassBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.isDark
            ? const Color(0xFF231D33)
            : Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
