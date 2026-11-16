import 'package:flutter/material.dart';

/// Uygulamanin gorsel kimligi.
/// Birincil renk: teal (guven, sakinlik). Vurgu: turuncu (eylem).
/// Acil durumlar icin ayri bir kirmizi tonu kullanilir.
class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF2DD4BF);
  static const Color accent = Color(0xFFEA580C);
  static const Color accentDark = Color(0xFFFB923C);
  static const Color urgent = Color(0xFFDC2626);
  static const Color urgentDark = Color(0xFFF87171);
  static const Color success = Color(0xFF059669);
  static const Color successDark = Color(0xFF34D399);

  static const Color lightBackground = Color(0xFFF2FBF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD5E9E5);
  static const Color lightText = Color(0xFF10322F);
  static const Color lightMuted = Color(0xFF5B7471);

  static const Color darkBackground = Color(0xFF0B1413);
  static const Color darkSurface = Color(0xFF12201E);
  static const Color darkBorder = Color(0xFF24403C);
  static const Color darkText = Color(0xFFE6F3F1);
  static const Color darkMuted = Color(0xFF8FA9A5);
}

/// Durum renklerini tema moduna gore veren yardimci.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.urgent,
    required this.urgentContainer,
    required this.success,
    required this.successContainer,
    required this.accent,
    required this.accentContainer,
    required this.muted,
    required this.border,
  });

  final Color urgent;
  final Color urgentContainer;
  final Color success;
  final Color successContainer;
  final Color accent;
  final Color accentContainer;
  final Color muted;
  final Color border;

  static const StatusColors light = StatusColors(
    urgent: AppColors.urgent,
    urgentContainer: Color(0xFFFEE9E9),
    success: AppColors.success,
    successContainer: Color(0xFFDFF5EC),
    accent: AppColors.accent,
    accentContainer: Color(0xFFFDEADC),
    muted: AppColors.lightMuted,
    border: AppColors.lightBorder,
  );

  static const StatusColors dark = StatusColors(
    urgent: AppColors.urgentDark,
    urgentContainer: Color(0xFF3A1A1A),
    success: AppColors.successDark,
    successContainer: Color(0xFF123228),
    accent: AppColors.accentDark,
    accentContainer: Color(0xFF3A2314),
    muted: AppColors.darkMuted,
    border: AppColors.darkBorder,
  );

  @override
  StatusColors copyWith({
    Color? urgent,
    Color? urgentContainer,
    Color? success,
    Color? successContainer,
    Color? accent,
    Color? accentContainer,
    Color? muted,
    Color? border,
  }) {
    return StatusColors(
      urgent: urgent ?? this.urgent,
      urgentContainer: urgentContainer ?? this.urgentContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      muted: muted ?? this.muted,
      border: border ?? this.border,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentContainer: Color.lerp(urgentContainer, other.urgentContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get status =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

class AppTheme {
  static const double radius = 16;
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);

  static ThemeData light() => _base(
        Brightness.light,
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightText,
          error: AppColors.urgent,
          onError: Colors.white,
          outlineVariant: AppColors.lightBorder,
        ),
        AppColors.lightBackground,
        StatusColors.light,
      );

  static ThemeData dark() => _base(
        Brightness.dark,
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primaryDark,
          onPrimary: const Color(0xFF00201C),
          secondary: AppColors.accentDark,
          onSecondary: const Color(0xFF2B1402),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkText,
          error: AppColors.urgentDark,
          onError: const Color(0xFF2B0A0A),
          outlineVariant: AppColors.darkBorder,
        ),
        AppColors.darkBackground,
        StatusColors.dark,
      );

  static ThemeData _base(
    Brightness brightness,
    ColorScheme scheme,
    Color background,
    StatusColors status,
  ) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      extensions: <ThemeExtension<dynamic>>[status],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: status.border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: status.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary,
        labelStyle: base.textTheme.labelLarge,
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: status.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: status.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: BorderSide(color: status.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      dividerTheme: DividerThemeData(color: status.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
