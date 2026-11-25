import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Arayanin yuvarlak isareti: adin bas harfleri, renkli bir zemin uzerinde.
///
/// Fotograf koymuyoruz: arayanin yuzunu bilmiyoruz. Bir stok ya da uretilmis
/// yuz koymak, var olmayan birini "Zeynep Öztürk" diye gostermek olurdu.
/// Gmail, Slack ve LinkedIn ayni durumda ayni seyi yapar: bas harfler.
/// Cizilmis bir karikatur yuze gore hem daha temiz durur hem de kucuk
/// boyutlarda okunur kalir.
///
/// Gercek fotograf istenirse dogru kaynak telefonun rehberi: numara
/// eslesirse kisinin kendi fotografi gosterilebilir. Bu, kisinin kendi
/// verisi oldugu icin dogru olur.
class CallerAvatar extends StatelessWidget {
  const CallerAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.statusColor,
  });

  final String name;
  final double size;

  /// Saga alta konan kucuk durum noktasi (acil, geri donus bekliyor...).
  final Color? statusColor;

  /// Zemin gradyanlari. Hepsi paletin yaninda durabilecek, birbirinden
  /// kolay ayrilan tonlar; ad hep ayni rengi alir.
  static const _palettes = <(Color, Color)>[
    (Color(0xFFF2994A), Color(0xFFEB5757)),
    (Color(0xFF3B82F6), Color(0xFF1E3A8A)),
    (Color(0xFF10B981), Color(0xFF047857)),
    (Color(0xFF8B5CF6), Color(0xFF5B21B6)),
    (Color(0xFFEC4899), Color(0xFF9D174D)),
    (Color(0xFF0EA5E9), Color(0xFF0369A1)),
    (Color(0xFFF59E0B), Color(0xFFB45309)),
    (Color(0xFF14B8A6), Color(0xFF0F766E)),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final seed = _seedOf(name);
    final (from, to) = _palettes[seed % _palettes.length];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [from, to],
              ),
              boxShadow: [
                BoxShadow(
                  color: to.withValues(alpha: 0.28),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.08),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
          if (statusColor != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.26,
                height: size * 0.26,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.glass, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Ilk iki kelimenin bas harfi. Arapca ve Turkce adlarda da calisir.
  static String _initials(String value) {
    final parts =
        value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final word = parts.first;
      return word.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  /// Addan sabit bir sayi: ayni ad hep ayni rengi alir.
  static int _seedOf(String value) {
    var hash = 7;
    for (final unit in value.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
