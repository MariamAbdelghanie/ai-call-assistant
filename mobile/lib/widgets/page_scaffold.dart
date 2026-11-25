import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Sade sayfa iskeleti.
///
/// Onceki surumde her ekranin tepesinde genis turuncu bir band vardi.
/// Band dikkat cekiyordu ama her sayfada tekrar edince icerigin onune
/// geciyor ve ekranin ucte birini yiyordu. Simdi zemin beyaz, baslik duz
/// metin, turuncu yalnizca vurgu (dugme, etiket, secili sekme) olarak
/// kullaniliyor.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.leading,
    this.actions,
    this.topBar,
    this.floating,
    this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 110),
  });

  final String title;
  final String? subtitle;

  /// Basligin solundaki oge (geri dugmesi gibi).
  final Widget? leading;

  /// Basligin saginda duran dugmeler.
  final List<Widget>? actions;

  /// Basligin ustunde duran satir (arama kutusu, profil...).
  final Widget? topBar;

  /// Sag altta duran eylem dugmesi.
  final Widget? floating;

  final Future<void> Function()? onRefresh;

  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    Widget list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (topBar != null) ...[
          topBar!,
          const SizedBox(height: 18),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style:
                          context.text.bodySmall?.copyWith(color: tokens.muted),
                    ),
                  ],
                ],
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );

    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh!, child: list);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            tokens.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: tokens.isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor:
            tokens.isDark ? AppPalette.darkSurface : AppPalette.surface,
        body: SafeArea(bottom: false, child: list),
        floatingActionButton: floating,
      ),
    );
  }
}

/// Bolum basligi: kucuk, turuncu ve kalin.
///
/// Gri bir basliga gore gruplari daha net ayiriyor ve turuncuyu sayfaya
/// buyuk bloklar koymadan tasimis oluyor.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.text.labelMedium?.copyWith(
                color: AppPalette.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Satirlari tek bir yuzeyde toplayan kart.
class CardGroup extends StatelessWidget {
  const CardGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.dividerIndent = 56,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.glass : AppPalette.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: tokens.glassBorder),
      ),
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: tokens.glassBorder,
              ),
            child,
          ],
        ],
      ),
    );
  }
}

/// Sag altta duran turuncu eylem dugmesi.
class ActionPillButton extends StatelessWidget {
  const ActionPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Alt gezinme cubugunun uzerine binmesin.
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppPalette.orange,
        borderRadius: BorderRadius.circular(999),
        elevation: 6,
        shadowColor: AppPalette.orange.withValues(alpha: 0.45),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: context.text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
