import 'package:flutter/material.dart';

/// Gorsel kimlik: nane yesili, krem ve pudra tonlarinda nese veren bir palet.
/// Yuzeyler buzlu cam, zemin yumusak degradelerden olusur.
class AppPalette {
  // Marka: derin mor-lila
  static const Color brand = Color(0xFF8B5CF6);
  static const Color brandLight = Color(0xFFB794F6);
  static const Color brandDeep = Color(0xFF6D28D9);
  static const Color blush = Color(0xFFF0A6D8);
  static const Color cyan = Color(0xFF5EE7D6);
  static const Color lilac = Color(0xFFC4B5FD);

  // Durum
  static const Color urgent = Color(0xFFFF5D8F);
  static const Color pending = Color(0xFFF0A741);
  static const Color success = Color(0xFF34D399);

  // Acik tema zemin duraklari
  static const List<Color> lightMesh = [
    Color(0xFFF3EEFF),
    Color(0xFFEDE4FF),
    Color(0xFFFBE9F7),
    Color(0xFFEAF3FF),
  ];

  // Koyu tema zemin duraklari (referans tasarimdaki gece moru)
  static const List<Color> darkMesh = [
    Color(0xFF170E2B),
    Color(0xFF241145),
    Color(0xFF2E1150),
    Color(0xFF140B22),
  ];

  static const Color lightText = Color(0xFF2A1B4A);
  static const Color lightMuted = Color(0xFF6E5E90);
  static const Color darkText = Color(0xFFF2EBFF);
  static const Color darkMuted = Color(0xFFA796C8);
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
    glass: Color(0x99FFFFFF),
    glassStrong: Color(0xD6FFFFFF),
    glassBorder: Color(0xA6FFFFFF),
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0x24FF5D8F),
    pending: AppPalette.pending,
    pendingSoft: Color(0x24F0A741),
    success: AppPalette.success,
    successSoft: Color(0x2434D399),
    shadow: Color(0x1A6D28D9),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: Color(0x14FFFFFF),
    glassStrong: Color(0x26FFFFFF),
    glassBorder: Color(0x30FFFFFF),
    muted: AppPalette.darkMuted,
    urgent: Color(0xFFFF7FAE),
    urgentSoft: Color(0x33FF7FAE),
    pending: Color(0xFFF7C579),
    pendingSoft: Color(0x33F7C579),
    success: Color(0xFF5EE7D6),
    successSoft: Color(0x335EE7D6),
    shadow: Color(0x66000000),
    isDark: true,
  );

  /// Dugme ve vurgular icin marka degradesi.
  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppPalette.brandLight, AppPalette.brand],
      );

  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.brandLight.withValues(alpha: isDark ? 0.26 : 0.38),
          AppPalette.blush.withValues(alpha: isDark ? 0.22 : 0.34),
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
          ? AppPalette.brandLight
          : AppPalette.brandDeep,
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
            ? const Color(0xFF261548)
            : Colors.white.withValues(alpha: 0.97),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
