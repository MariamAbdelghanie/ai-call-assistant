import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import '../utils/formatters.dart';

/// Kucuk, renk kodlu durum etiketi.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ust taraftaki sayisal ozet karti.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        radius: AppTheme.radiusSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste bos oldugunda gosterilen aciklayici durum.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 52),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: tokens.glass,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppPalette.brand),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium
                  ?.copyWith(color: tokens.muted, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sunucuya ulasilamadiginda listenin ustunde duran bilgi seridi.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: tokens.pendingSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: tokens.pending.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: tokens.pending),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('offlineDemo'),
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tokens.pending,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.t('offlineDemoHint'),
                  style: context.text.bodySmall
                      ?.copyWith(color: tokens.muted, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: Text(strings.t('tabSettings')),
          ),
        ],
      ),
    );
  }
}

/// Listedeki tek bir cagri karti.
class CallCard extends StatelessWidget {
  const CallCard({
    super.key,
    required this.call,
    required this.onTap,
    required this.onToggleCalledBack,
  });

  final CallSummary call;
  final VoidCallback onTap;
  final VoidCallback onToggleCalledBack;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final accent = call.isUrgent ? tokens.urgent : AppPalette.brand;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.32),
                        width: 1.4,
                      ),
                    ),
                    child: Text(
                      Formatters.initials(call.callerName),
                      style: context.text.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          call.callerName.isEmpty
                              ? strings.t('unnamed')
                              : call.callerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.friendly(call.timestamp, strings),
                          style: context.text.bodySmall
                              ?.copyWith(color: tokens.muted),
                        ),
                      ],
                    ),
                  ),
                  if (call.isUrgent)
                    StatusBadge(
                      label: strings.t('urgentBadge'),
                      foreground: tokens.urgent,
                      background: tokens.urgentSoft,
                      icon: Icons.bolt_rounded,
                    ),
                ],
              ),
              if (call.callerPurpose.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  call.callerPurpose,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (call.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  call.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium
                      ?.copyWith(color: tokens.muted, height: 1.5),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (call.hasAppointment)
                    StatusBadge(
                      label: call.appointmentInfo,
                      foreground: AppPalette.blush,
                      background: tokens.glass,
                      icon: Icons.event_available_rounded,
                    ),
                  if (call.awaitingCallback)
                    StatusBadge(
                      label: strings.t('callbackBadge'),
                      foreground: tokens.pending,
                      background: tokens.pendingSoft,
                      icon: Icons.phone_callback_rounded,
                    ),
                  if (call.calledBack)
                    StatusBadge(
                      label: strings.t('calledBack'),
                      foreground: tokens.success,
                      background: tokens.successSoft,
                      icon: Icons.check_circle_rounded,
                    ),
                  StatusBadge(
                    label: strings.languageName(call.lang),
                    foreground: tokens.muted,
                    background: tokens.muted.withValues(alpha: 0.12),
                    icon: Icons.translate_rounded,
                  ),
                ],
              ),
              if (call.callbackRequested) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: call.calledBack
                      ? OutlinedButton.icon(
                          onPressed: onToggleCalledBack,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: Text(strings.t('markNotCalledBack')),
                        )
                      : FilledButton.icon(
                          onPressed: onToggleCalledBack,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(strings.t('markCalledBack')),
                        ),
                ),
              ],
        ],
      ),
    );
  }
}
