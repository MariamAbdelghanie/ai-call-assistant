import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CALLORA gorsel kimligi: acik, sakin ve profesyonel bir SaaS yuzeyi.
///
/// Varsayilan gorunum ACIK moddur. Turuncu vurgu yalnizca onemli eylemler,
/// aktif durumlar ve kritik gostergeler icin kullanilir; genis yuzeylerde
/// kullanilmaz. Renk adlari kodun geri kalaniyla uyumlu kalsin diye korundu,
/// yalnizca degerleri yeni palete gore degistirildi.
class AppPalette {
  // --- Marka: beyaz zemin + turuncu vurgu ---
  static const Color orange = Color(0xFFF26B21); // birincil
  static const Color orangeSoft = Color(0xFFFFF1E8); // cok acik turuncu
  static const Color orangeTint = Color(0xFFFDE4D3); // kenarlik/rozet
  // Ucuncu renk: turuncuyu kiran koyu lacivert. Ikincil dugmeler, marka
  // isareti ve basliklarda kullanilir.
  static const Color ink = Color(0xFF16202E);
  static const Color inkSoft = Color(0xFFEDF1F6);

  /// Lacivert: turuncu ve beyazi kiran ucuncu renk. Turuncu dikkat cekmek
  /// icin, lacivert ise agirlik ve guven vermek icin kullanilir; ikisi ayni
  /// yuzeyde yarismasin diye lacivert hep genis bloklarda, turuncu hep
  /// kucuk vurgularda durur.
  static const Color indigo = Color(0xFF1B2A4A);
  static const Color indigoDeep = Color(0xFF111C33);
  static const Color indigoSoft = Color(0xFFE8ECF5);

  static const Color accent = orange;
  static const Color accentDeep = Color(0xFFD4551A);
  static const Color accentSoft = orangeSoft;

  // --- Notr yuzeyler (acik tema) ---
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF7F7F8);
  static const Color border = Color(0xFFECECEE);

  // --- Notr yuzeyler (koyu tema) ---
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkCard = Color(0xFF1C1C1F);
  static const Color darkBorder = Color(0xFF2A2A2E);

  // --- Metin ---
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightMuted = Color(0xFF8A8A8E);
  static const Color darkText = Color(0xFFF2F2F3);
  static const Color darkMuted = Color(0xFF9A9AA0);

  // --- Durum renkleri ---
  static const Color urgent = Color(0xFFE5484D);
  static const Color pending = Color(0xFFE0890B);
  static const Color success = Color(0xFF2FA86A);
  static const Color info = Color(0xFF3B82F6);

  /// Randevu/ajanda icin yumusak indigo: turuncuyla carpismayan tek
  /// soguk ton, boylece takvim ogeleri listede kendiliginden ayrisiyor.
  static const Color scheduled = Color(0xFF5B6CD9);

  // --- Geriye donuk uyumluluk ---
  static const Color brand = orange;
  static const Color brandLight = Color(0xFFFF9459);
  static const Color brandDeep = accentDeep;
  static const Color navy = ink;
  static const Color navyDeep = Color(0xFF0E0E0F);
  static const Color navyLight = Color(0xFFFF9459);
  static const Color clay = pending;
  static const Color clayLight = orangeTint;
  static const Color beige = orangeSoft;
  static const Color paper = surfaceAlt;
  static const Color forest = accentDeep;
  static const Color sage = orange;
  static const Color sageMid = Color(0xFFFF9459);
  static const Color sageLight = orangeTint;
  static const Color mistBlue = Color(0xFFFF9459);
  static const Color deepSlate = darkSurface;
  static const Color mistWhite = surface;
  static const Color blush = Color(0xFFFF9459);
  static const Color mint = success;
  static const Color peach = pending;
  static const Color violet = info;
  static const Color neonCyan = info;
  static const Color cyan = info;
  static const Color lilac = orangeTint;

  static const List<Color> lightMesh = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFFFCFCFD),
    Color(0xFFFFFFFF),
  ];

  static const List<Color> darkMesh = [
    darkSurface,
    Color(0xFF171719),
    darkSurface,
    Color(0xFF111113),
  ];
}

/// Yuzey, kenarlik, golge ve durum renkleri icin tema uzantisi.
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

  /// Zemin gecisleri.
  final List<Color> mesh;

  /// Kart zemini. (Ad gecmisten geliyor; artik cam degil duz yuzey.)
  final Color glass;

  /// One cikan kart zemini.
  final Color glassStrong;

  /// Kenarlik rengi.
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
    glass: AppPalette.surface,
    glassStrong: AppPalette.surfaceAlt,
    glassBorder: AppPalette.border,
    muted: AppPalette.lightMuted,
    urgent: AppPalette.urgent,
    urgentSoft: Color(0xFFFDEAEA),
    pending: AppPalette.pending,
    pendingSoft: Color(0xFFFDF0DC),
    success: AppPalette.success,
    successSoft: Color(0xFFE6F6EE),
    shadow: Color(0x12101828),
    isDark: false,
  );

  static const AppTokens dark = AppTokens(
    mesh: AppPalette.darkMesh,
    glass: AppPalette.darkCard,
    glassStrong: Color(0xFF28282C),
    glassBorder: AppPalette.darkBorder,
    muted: AppPalette.darkMuted,
    urgent: Color(0xFFF87171),
    urgentSoft: Color(0xFF3B1D1D),
    pending: Color(0xFFFBBF24),
    pendingSoft: Color(0xFF3A2D12),
    success: Color(0xFF6FBF8E),
    successSoft: Color(0xFF14261D),
    shadow: Color(0x4D000000),
    isDark: true,
  );

  /// Yumusak turuncu gecis: yalnizca kucuk vurgu yuzeylerinde kullanilir.
  LinearGradient get fourColorGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppPalette.sageMid,
          AppPalette.accent,
          AppPalette.forest,
        ],
        stops: [0.0, 0.55, 1.0],
      );

  /// Birincil dugmeler ve aktif durumlar icin marka gecisi.
  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [AppPalette.accent, AppPalette.sageMid],
      );

  /// Kart ve panellerde cok hafif zemin tonu.
  LinearGradient get softGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [AppPalette.darkCard, Color(0xFF161D19)]
            : const [Color(0xFFFFFFFF), AppPalette.paper],
      );

  /// Kartlarda kullanilan olculu golge.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

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
  /// Kart ve buyuk yuzeyler icin kose yaricapi.
  static const double radius = 16;

  /// Dugme, alan ve kucuk bilesenler icin kose yaricapi.
  static const double radiusSm = 12;

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);

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
      seedColor: AppPalette.accent,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppPalette.sageLight : AppPalette.accent,
      onPrimary: isDark ? AppPalette.forest : Colors.white,
      secondary: isDark ? AppPalette.sageLight : AppPalette.accent,
      onSecondary: Colors.white,
      surface: Colors.transparent,
      onSurface: onSurface,
      surfaceContainerHighest: tokens.glassStrong,
      error: tokens.urgent,
      onError: Colors.white,
      outline: tokens.glassBorder,
      outlineVariant: tokens.glassBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[tokens],
    );

    // Inter: is uygulamalarinda okunakli, notr ve yaygin bir aile.
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.5),
        bodySmall: textTheme.bodySmall?.copyWith(height: 1.45),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: textTheme.labelSmall?.copyWith(letterSpacing: 0.2),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        backgroundColor: tokens.glass,
        selectedColor: AppPalette.accent,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? tokens.glass : AppPalette.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.muted),
        floatingLabelStyle:
            textTheme.labelLarge?.copyWith(color: AppPalette.accent),
        prefixIconColor: tokens.muted,
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
          borderSide: const BorderSide(color: AppPalette.accent, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          backgroundColor: AppPalette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          foregroundColor: onSurface,
          side: BorderSide(color: tokens.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppPalette.darkCard : AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppPalette.accentSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.glassBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppPalette.darkCard : AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
