import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'caller_avatar.dart';
import 'page_scaffold.dart';

/// Ustteki arama satiri: arama kutusu ve saginda profil dairesi.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.initials,
    required this.photoUrl,
    required this.onProfile,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final String initials;
  final String? photoUrl;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = AppStrings.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: tokens.isDark ? tokens.glass : AppPalette.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.glassBorder),
            ),
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: strings.t('searchCalls'),
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon:
                    Icon(Icons.search_rounded, size: 20, color: tokens.muted),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: tokens.muted,
                        onPressed: () {
                          controller.clear();
                          onChanged();
                        },
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onProfile,
          child: CircleAvatar(
            radius: 21,
            backgroundColor: AppPalette.orangeSoft,
            foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
            child: Text(
              initials,
              style: context.text.titleSmall?.copyWith(
                color: AppPalette.accentDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Asistanin acik olup olmadigini gosteren ve acip kapatan kart.
class AssistantCard extends StatelessWidget {
  const AssistantCard({
    super.key,
    required this.enabled,
    required this.hours,
    required this.onChanged,
  });

  final bool enabled;
  final String hours;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: enabled
            ? AppPalette.orangeSoft
            : (tokens.isDark ? tokens.glass : AppPalette.surfaceAlt),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: enabled
              ? AppPalette.orange.withValues(alpha: 0.28)
              : tokens.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: enabled ? AppPalette.orange : tokens.muted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.graphic_eq_rounded,
                size: 19, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.t(enabled ? 'assistantOn' : 'assistantOff'),
                  style: context.text.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? '${strings.t('answeringNow')} · $hours'
                      : strings.t('answeringOff'),
                  style: context.text.bodySmall?.copyWith(
                    color: tokens.muted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Dort ozet rakam: halka ya da kart yok, sadece rakam ve etiket.
///
/// Halkalar guzel duruyordu ama dort ayri cember sayfanin en ustunde fazla
/// gurultu yapiyordu; rakamin kendisi zaten bilginin tamami.
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<({int value, String label, Color color, VoidCallback? onTap})>
      items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      children: [
        for (final item in items)
          Expanded(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      '${item.value}',
                      style: context.text.headlineSmall?.copyWith(
                        color: item.color,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          context.text.labelSmall?.copyWith(color: tokens.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Son yedi gunun cagri dagilimi: ince cubuklar, bugun turuncu.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.calls});

  final List<CallSummary> calls;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final data = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = calls.where((c) {
        final t = c.timestamp;
        return t != null &&
            t.year == day.year &&
            t.month == day.month &&
            t.day == day.day;
      }).length;
      return (day: day, count: count);
    });
    final maxCount = data.fold<int>(1, (m, e) => math.max(m, e.count));
    final total = data.fold<int>(0, (s, e) => s + e.count);

    // En yogun saat: cubuklarin yaninda tek satirlik ek bilgi.
    final perHour = <int, int>{};
    for (final c in calls) {
      final t = c.timestamp;
      if (t == null) continue;
      perHour[t.hour] = (perHour[t.hour] ?? 0) + 1;
    }
    int? peak;
    var best = 0;
    perHour.forEach((hour, count) {
      if (count > best) {
        best = count;
        peak = hour;
      }
    });

    final labels = strings.weekdayInitials();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: tokens.isDark ? tokens.glass : AppPalette.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: tokens.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.t('weeklyTitle'),
                style: context.text.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                peak == null
                    ? '$total ${strings.t('weeklyCalls')}'
                    : '$total ${strings.t('weeklyCalls')} · '
                        '${strings.t('weeklyBusiest')} '
                        '${peak.toString().padLeft(2, '0')}:00',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, bucket) in data.indexed)
                  Expanded(
                    child: _Bar(
                      ratio: bucket.count / maxCount,
                      count: bucket.count,
                      label: i == data.length - 1
                          ? strings.t('today')
                          : labels[bucket.day.weekday - 1],
                      highlight: i == data.length - 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.ratio,
    required this.count,
    required this.label,
    required this.highlight,
  });

  final double ratio;
  final int count;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = highlight ? AppPalette.orange : AppPalette.orangeTint;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count == 0 ? '' : '$count',
          style: context.text.labelSmall?.copyWith(
            color: highlight ? AppPalette.orange : tokens.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 6 + ratio * 36,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: highlight ? AppPalette.orange : tokens.muted,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Listedeki tek cagri satiri.
class CallRow extends StatelessWidget {
  const CallRow({super.key, required this.call, required this.onTap});

  final CallSummary call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final (tagLabel, tagColor) = call.isUrgent
        ? (strings.t('filterUrgent'), tokens.urgent)
        : call.hasAppointment
            ? (strings.t('statAppointment'), AppPalette.scheduled)
            : call.awaitingCallback
                ? (strings.t('filterCallback'), tokens.pending)
                : ('', Colors.transparent);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CallerAvatar(name: call.callerName, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          call.callerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.friendly(call.timestamp, strings),
                        style: context.text.labelSmall
                            ?.copyWith(color: tokens.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    call.summary.trim().isEmpty
                        ? call.callerPurpose
                        : call.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall
                        ?.copyWith(color: tokens.muted, height: 1.35),
                  ),
                  if (tagLabel.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tagLabel,
                          style: context.text.labelSmall?.copyWith(
                            color: tagColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon + baslik + alt baslik + sagda deger ve ok iceren genel satir.
class AppRow extends StatelessWidget {
  const AppRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tint = danger ? tokens.urgent : AppPalette.orange;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: danger ? tokens.urgent : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall
                          ?.copyWith(color: tokens.muted),
                    ),
                  ],
                ],
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
                  style: context.text.bodySmall?.copyWith(color: tokens.muted),
                ),
              ),
            ],
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: tokens.muted),
            ],
          ],
        ),
      ),
    );
  }
}
