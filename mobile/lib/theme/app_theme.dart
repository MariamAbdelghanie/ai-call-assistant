import 'package:flutter/material.dart';

/// Mindora-inspired visual identity:
/// Exact palette from the design specification:
/// 1. #5E887E - Sage Green (Eucalyptus)
/// 2. #A7C7E7 - Mist Blue (Airy Sky)
/// 3. #2F3E46 - Deep Slate (Forest Charcoal)
/// 4. #F1F5F4 - Mist White (Clean Atmosphere)
/// 5. #EBAEB7 - Soft Blush (Dusty Rose Accent)
class AppPalette {
  // 4 Main Colors + 1 Accent from the Mindora UI Kit:
  static const Color sage = Color(0xFF5E887E);
  static const Color mistBlue = Color(0xFFA7C7E7);
  static const Color deepSlate = Color(0xFF2F3E46);
  static const Color mistWhite = Color(0xFFF1F5F4);
  static const Color blush = Color(0xFFEBAEB7);

  // Semantic mappings
  static const Color brand = Color(0xFF5E887E);
  static const Color brandLight = Color(0xFFA7C7E7);
  static const Color brandDeep = Color(0xFF2F3E46);
  static const Color cyan = Color(0xFFA7C7E7);
  static const Color lilac = Color(0xFFBACEC7);

  // Status colors that harmonise with the serene palette
  static const Color urgent = Color(0xFFD9536B);
  static const Color pending = Color(0xFFCDA04A);
  static const Color success = Color(0xFF34B88A);

  // Light theme background stops (serene misty landscape)
  static const List<Color> lightMesh = [
    Color(0xFFF1F5F4),
    Color(0xFFE4EDE9),
    Color(0xFFDBE7E4),
    Color(0xFFEDF3F1),
  ];

  // Dark theme background stops (deep pine forest twilight)
  static const List<Color> darkMesh = [
    Color(0xFF14201E),
    Color(0xFF1C2C29),
    Color(0xFF243632),
    Color(0xFF121B19),
  ];

  static const Color lightText = Color(0xFF2F3E46);
  static const Color lightMuted = Color(0xFF6B867F);
  static const Color darkText = Color(0xFFF1F5F4);
  static const Color darkMuted = Color(0xFF9AB2AB);
}

/// Theme extension for glass surfaces, gradients, and status tokens.
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
    glass: Color(0x99FFFFFF),
    glassStrong: Color(0xD6FFFFFF),
    glassBorder: Color(0x80D5E4DE),
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0x20D9536B),
    pending: AppPalette.pending,
    pendingSoft: Color(0x20CDA04A),
    success: AppPalette.success,
    successSoft: Color(0x2034B88A),
    shadow: Color(0x142F3E46),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: Color(0x18FFFFFF),
    glassStrong: Color(0x2BFFFFFF),
    glassBorder: Color(0x335E887E),
    muted: AppPalette.darkMuted,
    urgent: Color(0xFFE87A8E),
    urgentSoft: Color(0x33E87A8E),
    pending: Color(0xFFDDB86A),
    pendingSoft: Color(0x33DDB86A),
    success: Color(0xFF5EE7C0),
    successSoft: Color(0x335EE7C0),
    shadow: Color(0x66000000),
    isDark: true,
  );

  /// 4-Color blended gradient combining the top 4 palette colors:
  /// #5E887E (Sage), #A7C7E7 (Mist Blue), #2F3E46 (Deep Slate), #F1F5F4 (Mist White)
  LinearGradient get fourColorGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.sage,
          AppPalette.mistBlue,
          AppPalette.deepSlate,
          AppPalette.mistWhite,
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      );

  /// Brand gradient for buttons and active states.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? const [Color(0xFF4C736A), Color(0xFF385750)]
            : const [AppPalette.sage, Color(0xFF486E65)],
      );

  /// Soft ethereal multi-color gradient for cards and hero panels.
  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.sage.withValues(alpha: isDark ? 0.22 : 0.30),
          AppPalette.mistBlue.withValues(alpha: isDark ? 0.18 : 0.25),
          AppPalette.blush.withValues(alpha: isDark ? 0.14 : 0.20),
        ],
        stops: const [0.0, 0.55, 1.0],
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
  static const double radius = 24;
  static const double radiusSm = 16;
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
      seedColor: AppPalette.sage,
      brightness: brightness,
    ).copyWith(
      primary: brightness == Brightness.dark
          ? AppPalette.mistBlue
          : AppPalette.sage,
      onPrimary: Colors.white,
      secondary: AppPalette.blush,
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
      scaffoldBackgroundColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    final textTheme = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
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
          letterSpacing: -0.5,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: tokens.glass,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: tokens.glassBorder),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: tokens.glassBorder),
        shape: const StadiumBorder(),
        backgroundColor: tokens.glass,
        selectedColor: scheme.primary,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.glass,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.glassBorder, thickness: 1),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.isDark
            ? const Color(0xFF1B2B28)
            : Colors.white.withValues(alpha: 0.98),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
