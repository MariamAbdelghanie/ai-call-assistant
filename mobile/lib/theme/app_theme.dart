import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CALLORA visual system: restrained graphite surfaces with a focused
/// safety-orange accent. Keep semantic colors separate from brand colors.
class AppPalette {
  static const Color stormGrey = Color(0xFF77777B);
  static const Color matteBlack = Color(0xFF171719);
  static const Color safetyOrange = Color(0xFFFF5F00);

  // Compatibility aliases used by existing widgets.
  static const Color sage = safetyOrange;
  static const Color mistBlue = Color(0xFFFF8A45);
  static const Color deepSlate = matteBlack;
  static const Color mistWhite = Color(0xFFF7F7F8);
  static const Color blush = Color(0xFFFF8A45);
  static const Color mint = Color(0xFF26966B);
  static const Color peach = Color(0xFFD58A32);
  static const Color violet = Color(0xFF77777B);
  static const Color neonCyan = Color(0xFF6E9EAD);

  static const Color brand = safetyOrange;
  static const Color brandLight = Color(0xFFFF8A45);
  static const Color brandDeep = Color(0xFFD94F00);
  static const Color cyan = Color(0xFF6E9EAD);
  static const Color lilac = stormGrey;

  static const Color urgent = Color(0xFFD94848);
  static const Color pending = Color(0xFFD58A32);
  static const Color success = Color(0xFF26966B);

  static const List<Color> lightMesh = [
    Color(0xFFF7F7F8),
    Color(0xFFF1F1F2),
    Color(0xFFF7F7F8),
    Color(0xFFFFFFFF),
  ];

  static const List<Color> darkMesh = [
    Color(0xFF171719),
    Color(0xFF1D1D20),
    Color(0xFF171719),
    Color(0xFF141416),
  ];

  static const Color lightText = Color(0xFF202023);
  static const Color lightMuted = Color(0xFF77777B);
  static const Color darkText = Color(0xFFF5F5F6);
  static const Color darkMuted = Color(0xFFAAAAB0);
}

/// Shared semantic tokens consumed by existing screens and widgets.
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
    glass: Color(0xFFFFFFFF),
    glassStrong: Color(0xFFF0F0F1),
    glassBorder: Color(0xFFE1E1E3),
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0x1FD94848),
    pending: AppPalette.pending,
    pendingSoft: Color(0x1FD58A32),
    success: AppPalette.success,
    successSoft: Color(0x1F26966B),
    shadow: Color(0x12000000),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: Color(0xFF222225),
    glassStrong: Color(0xFF2B2B2F),
    glassBorder: Color(0xFF38383D),
    muted: AppPalette.darkMuted,
    urgent: Color(0xFFFF7777),
    urgentSoft: Color(0x33FF7777),
    pending: Color(0xFFE6AD65),
    pendingSoft: Color(0x33E6AD65),
    success: Color(0xFF62C99A),
    successSoft: Color(0x3362C99A),
    shadow: Color(0x66000000),
    isDark: true,
  );

  LinearGradient get fourColorGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF303034), AppPalette.matteBlack]
            : const [Colors.white, Color(0xFFECECEE)],
      );

  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppPalette.safetyOrange, Color(0xFFFF7A2B)],
      );

  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0x22FF5F00), Color(0x0838383D)]
            : const [Color(0x14FF5F00), Color(0x08FFFFFF)],
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
  static const double radius = 20;
  static const double radiusSm = 14;
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
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.safetyOrange,
      brightness: brightness,
    ).copyWith(
      primary: AppPalette.safetyOrange,
      onPrimary: Colors.white,
      secondary: AppPalette.stormGrey,
      surface: tokens.glass,
      onSurface: onSurface,
      error: tokens.urgent,
      onError: Colors.white,
      outlineVariant: tokens.glassBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppPalette.matteBlack : const Color(0xFFF7F7F8),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.0,
          height: 1.08,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
        bodySmall: textTheme.bodySmall?.copyWith(height: 1.45),
        labelSmall: textTheme.labelSmall?.copyWith(letterSpacing: 0.2),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.15,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
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
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
          borderSide: const BorderSide(
            color: AppPalette.safetyOrange,
            width: 1.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppPalette.safetyOrange,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          side: BorderSide(color: tokens.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.glass,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x22FF5F00),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.glassBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF303034) : const Color(0xFF252528),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.glass,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
