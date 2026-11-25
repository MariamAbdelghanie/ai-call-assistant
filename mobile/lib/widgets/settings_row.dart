import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ayarlar listesindeki tek satir: ikon, baslik, saginda deger ve ok.
///
/// Her ayari acik acik ekrana sermek yerine satir halinde gostermek,
/// sayfayi bir form yiginindan cikarip okunabilir bir listeye cevirir;
/// kullanici ne ayari oldugunu ve su anki degeri tek bakista gorur,
/// degistirmek isterse satira dokunur.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.valueColor,
  });

  final IconData icon;
  final String label;

  /// Satirin saginda gorunen su anki deger.
  final String? value;

  /// Dokununca acilacak secim. null ise satir bilgi amaclidir.
  final VoidCallback? onTap;

  /// Ok yerine konacak oge (anahtar gibi).
  final Widget? trailing;

  /// Silme gibi geri alinamayan islemler icin kirmizi gosterim.
  final bool danger;

  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tint = danger ? tokens.urgent : AppPalette.indigo;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: danger
                    ? tokens.urgentSoft
                    : (tokens.isDark
                        ? tokens.glassStrong
                        : AppPalette.indigoSoft),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  color: danger ? tokens.urgent : null,
                ),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: valueColor ?? tokens.muted,
                    fontWeight: valueColor == null
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 21, color: tokens.muted),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satirlari tek bir beyaz yuzeyde toplayan kart.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: tokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.glass,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: tokens.glassBorder),
              boxShadow: tokens.cardShadow,
            ),
            child: Column(
              children: [
                for (final (index, row) in rows.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 65,
                      color: tokens.glassBorder,
                    ),
                  row,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Satira dokununca acilan secim yapragi.
///
/// Secenekleri ayri bir sayfaya goturmek yerine yapraka koymak, ayarin
/// baglamini (arkada duran liste) ekranda birakiyor.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<({T value, String label, String? hint, IconData? icon})> items,
  required T selected,
}) {
  final tokens = context.tokens;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: tokens.isDark ? AppPalette.darkSurface : Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 2, 22, 2),
            child: Text(
              title,
              style: context.text.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
              child: Text(
                subtitle,
                style: context.text.bodySmall?.copyWith(color: tokens.muted),
              ),
            ),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              leading: item.icon == null
                  ? null
                  : Icon(
                      item.icon,
                      color: item.value == selected
                          ? AppPalette.orange
                          : tokens.muted,
                    ),
              title: Text(
                item.label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: item.value == selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              subtitle: item.hint == null ? null : Text(item.hint!),
              trailing: item.value == selected
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppPalette.orange)
                  : const Icon(Icons.circle_outlined, color: Color(0xFFD5D5DA)),
              onTap: () => Navigator.of(sheetContext).pop(item.value),
            ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}
