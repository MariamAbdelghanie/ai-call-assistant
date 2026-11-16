import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../theme/app_theme.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
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
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: context.status.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$value',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: context.status.muted),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: context.status.muted, height: 1.5),
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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.status.accentContainer,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: context.status.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 18, color: context.status.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t('offlineDemo'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.status.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.t('offlineDemoHint'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: context.status.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final status = context.status;
    final accentColor = call.isUrgent ? status.urgent : theme.colorScheme.primary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Formatters.initials(call.callerName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.friendly(call.timestamp, strings),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: status.muted),
                        ),
                      ],
                    ),
                  ),
                  if (call.isUrgent)
                    StatusBadge(
                      label: strings.t('urgentBadge'),
                      foreground: status.urgent,
                      background: status.urgentContainer,
                      icon: Icons.priority_high_rounded,
                    ),
                ],
              ),
              if (call.callerPurpose.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  call.callerPurpose,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accentColor,
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
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (call.hasAppointment)
                    StatusBadge(
                      label: call.appointmentInfo,
                      foreground: theme.colorScheme.primary,
                      background:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      icon: Icons.event_available_outlined,
                    ),
                  if (call.awaitingCallback)
                    StatusBadge(
                      label: strings.t('callbackBadge'),
                      foreground: status.accent,
                      background: status.accentContainer,
                      icon: Icons.phone_callback_outlined,
                    ),
                  if (call.calledBack)
                    StatusBadge(
                      label: strings.t('calledBack'),
                      foreground: status.success,
                      background: status.successContainer,
                      icon: Icons.check_circle_outline,
                    ),
                  StatusBadge(
                    label: strings.languageName(call.lang),
                    foreground: status.muted,
                    background: status.muted.withValues(alpha: 0.12),
                    icon: Icons.translate_outlined,
                  ),
                ],
              ),
              if (call.callbackRequested) ...[
                const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
