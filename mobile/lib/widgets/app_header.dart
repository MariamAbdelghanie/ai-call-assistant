import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Turuncu ust basligi olan sayfa iskeleti.
///
/// Referans uygulamalarda her ekran, altta yuvarlatilmis turuncu bir
/// baslik bandiyla acilir; icerik bu bandin uzerine biner. Bu, duz beyaz
/// ekranlara gore hem daha bitmis durur hem de sayfanin nerede baslayip
/// nerede bittigini netlestirir.
class AppHeaderScaffold extends StatelessWidget {
  const AppHeaderScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.leading,
    this.headerChild,
    this.overlap = 0,
  });

  final String title;
  final String? subtitle;

  /// Basligin sagindaki dugmeler.
  final List<Widget>? actions;

  /// Basligin solundaki oge (ornegin profil fotografi).
  final Widget? leading;

  /// Basligin icinde, baslik metninin altinda yer alan ek icerik
  /// (arama kutusu, durum seridi, filtre cipleri...).
  final Widget? headerChild;

  /// Govdenin baslik uzerine ne kadar binecegi. Kart seridini banda
  /// oturtmak icin kullanilir.
  final double overlap;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Turuncu bandin uzerinde saat ve pil simgeleri beyaz olmali; yoksa
    // koyu simgeler turuncunun uzerinde okunmuyor.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      backgroundColor:
          tokens.isDark ? AppPalette.darkSurface : const Color(0xFFF7F7F8),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.accentDeep, AppPalette.orange],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(26),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, overlap > 0 ? 18 + overlap : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions != null) ...actions!,
                      ],
                    ),
                    if (headerChild != null) ...[
                      const SizedBox(height: 16),
                      headerChild!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: Offset(0, -overlap),
              child: body,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Turuncu bandin uzerinde duran yuvarlak buton.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// Turuncu bandin icindeki durum seridi (asistan acik / mesai).
class HeaderStatusStrip extends StatelessWidget {
  const HeaderStatusStrip({
    super.key,
    required this.label,
    required this.hours,
    required this.online,
  });

  final String label;
  final String hours;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF7BE8B3) : Colors.white70,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: context.text.titleSmall?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Icon(Icons.schedule_rounded,
              size: 15, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            hours,
            style: context.text.bodySmall?.copyWith(
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Turuncu bandin icinde duran durum sekmeleri (Bekleyen / Tamamlandi).
///
/// Sekmeleri bandin icine koymak, listenin ustunde ayri bir filtre kutusu
/// acmaktan daha az yer yiyor ve hangi kumeyi gordugunu basligin bir
/// parcasi olarak okutuyor.
class HeaderSegmented extends StatelessWidget {
  const HeaderSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          for (final (index, label) in labels.indexed)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: index == selected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      color: index == selected
                          ? AppPalette.accentDeep
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Turuncu bandin icindeki arama kutusu.
class HeaderSearchField extends StatelessWidget {
  const HeaderSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

/// Turuncu bandin icinde hafta secici.
///
/// Randevular ekraninda "hangi gun" sorusu listenin kendisinden once gelir.
/// Bu serit haftayi yedi kutu halinde gosterir, dolu gunlerin altina bir
/// nokta koyar ve secili gunu beyaza cevirir; oklarla hafta degisir.
class HeaderWeekStrip extends StatelessWidget {
  const HeaderWeekStrip({
    super.key,
    required this.weekStart,
    required this.selected,
    required this.dayLabels,
    required this.hasItems,
    required this.onSelect,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.rangeLabel,
  });

  /// Gosterilen haftanin pazartesi gunu.
  final DateTime weekStart;

  /// Secili gun; null ise tum hafta gosteriliyor demektir.
  final DateTime? selected;

  /// Pazartesiden pazara, iki harflik gun kisaltmalari.
  final List<String> dayLabels;

  /// O gun randevu var mi.
  final bool Function(DateTime day) hasItems;

  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final String rangeLabel;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            _Arrow(icon: Icons.chevron_left_rounded, onTap: onPrevWeek),
            Expanded(
              child: Text(
                rangeLabel,
                textAlign: TextAlign.center,
                style: context.text.titleSmall?.copyWith(color: Colors.white),
              ),
            ),
            _Arrow(icon: Icons.chevron_right_rounded, onTap: onNextWeek),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayCell(
                  day: weekStart.add(Duration(days: i)),
                  label: dayLabels[i % dayLabels.length],
                  selected: selected != null &&
                      _same(selected!, weekStart.add(Duration(days: i))),
                  isToday: _same(today, weekStart.add(Duration(days: i))),
                  marked: hasItems(weekStart.add(Duration(days: i))),
                  onTap: () => onSelect(weekStart.add(Duration(days: i))),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.label,
    required this.selected,
    required this.isToday,
    required this.marked,
    required this.onTap,
  });

  final DateTime day;
  final String label;
  final bool selected;
  final bool isToday;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : (isToday
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                color: selected
                    ? AppPalette.accentDeep
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${day.day}',
              style: context.text.titleSmall?.copyWith(
                color: selected ? AppPalette.accentDeep : Colors.white,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: marked
                    ? (selected ? AppPalette.orange : Colors.white)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turuncu bandin icinde hesap satiri: fotograf, ad, e-posta.
class HeaderProfile extends StatelessWidget {
  const HeaderProfile({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.trailing,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? 'C'
        : name.trim().characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.26),
            foregroundImage:
                photoUrl == null ? null : NetworkImage(photoUrl!),
            child: Text(
              initial,
              style: context.text.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
