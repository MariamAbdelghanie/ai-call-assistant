import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
