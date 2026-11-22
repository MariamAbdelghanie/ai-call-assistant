import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gorsel kimlik: yumusak pastel tonlar, lila-pembe-gok mavisi ucgeni.
///
/// Amac gozu yormayan, sakin ve "yazilim araci" gibi degil arkadas canlisi
/// duran bir yuzey. Renk adlari kodun geri kalaniyla uyumlu kalsin diye
/// korundu; yalnizca degerleri pastel paletle degistirildi.
class AppPalette {
  // Koyu mor zemin uzerinde neon mor-macenta vurgu.
  static const Color sage = Color(0xFFA855F7); // ana mor
  static const Color mistBlue = Color(0xFFC4A6FF); // acik mor
  static const Color deepSlate = Color(0xFF120A24); // koyu zemin
  static const Color mistWhite = Color(0xFFF5F3FF); // acik metin
  static const Color blush = Color(0xFFE879F9); // macenta vurgu

  // Kategori renkleri
  static const Color mint = Color(0xFF34D399);
  static const Color peach = Color(0xFFFBBF4A);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color neonCyan = Color(0xFF67E8F9);

  // Anlamsal esleme
  static const Color brand = Color(0xFFA855F7);
  static const Color brandLight = Color(0xFFC4A6FF);
  static const Color brandDeep = Color(0xFF6D28D9);
  static const Color cyan = Color(0xFF67E8F9);
  static const Color lilac = Color(0xFF8B5CF6);

  // Status colors that harmonise with the serene palette
  static const Color urgent = Color(0xFFFB5E7E);
  static const Color pending = Color(0xFFFBBF4A);
  static const Color success = Color(0xFF34D399);

  // Light theme background stops (serene misty landscape)
  static const List<Color> lightMesh = [
    Color(0xFFFBFAFF),
    Color(0xFFF6F3FD),
    Color(0xFFF9F6FE),
    Color(0xFFFDFCFF),
  ];

  // Dark theme background stops (deep pine forest twilight)
  static const List<Color> darkMesh = [
    Color(0xFF050309),
    Color(0xFF07040D),
    Color(0xFF0A0612),
    Color(0xFF030106),
  ];

  static const Color lightText = Color(0xFF1E1333);
  static const Color lightMuted = Color(0xFF756B8C);
  static const Color darkText = Color(0xFFF5F3FF);
  static const Color darkMuted = Color(0xFFA99CC9);
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
    glass: Color(0xFFFFFFFF),
    glassStrong: Color(0xFFFFFFFF),
    glassBorder: Color(0x1FA855F7),
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0x1FF2545B),
    pending: AppPalette.pending,
    pendingSoft: Color(0x1FF5A623),
    success: AppPalette.success,
    successSoft: Color(0x2034B88A),
    shadow: Color(0x142F3E46),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: Color(0xF00E0A18),
    glassStrong: Color(0xF5141026),
    glassBorder: Color(0x1FFFFFFF),
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
          Color(0xFFC084FC),
          Color(0xFFA855F7),
          Color(0xFF7C3AED),
        ],
        stops: [0.0, 0.55, 1.0],
      );

  /// Brand gradient for buttons and active states.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isDark
            ? const [Color(0xFF7C3AED), Color(0xFFB36CF8)]
            : const [Color(0xFF9F5BF0), Color(0xFFC084FC)],
      );

  /// Soft ethereal multi-color gradient for cards and hero panels.
  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.sage.withValues(alpha: isDark ? 0.20 : 0.07),
          AppPalette.mistBlue.withValues(alpha: isDark ? 0.16 : 0.06),
          AppPalette.blush.withValues(alpha: isDark ? 0.13 : 0.06),
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
  static const double radius = 28;
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

    final textTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          height: 1.08,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.55),
        bodySmall: textTheme.bodySmall?.copyWith(height: 1.5),
        labelSmall: textTheme.labelSmall?.copyWith(letterSpacing: 0.4),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
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
