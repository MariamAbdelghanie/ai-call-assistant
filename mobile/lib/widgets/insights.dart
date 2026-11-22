import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'soft_icon.dart';

/// Cagri verisinden turetilen kucuk gostergeler.
///
/// Sayfanin tamami ayni bicimde beyaz kutulardan olusunca tekduze gorunuyordu.
/// Bu kartlar farkli bir gorsel dil (cubuk grafik, oranlar, buyuk rakam)
/// getirerek hem ritmi kirar hem de asistanin ne is yaptigini somut gosterir.

/// Son yedi gunun cagri dagilimi.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.calls});

  final List<CallSummary> calls;

  /// Bugunden geriye yedi gun, en eski solda.
  List<({DateTime day, int count})> _buckets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final count = calls.where((c) {
        final t = c.timestamp;
        if (t == null) return false;
        return t.year == day.year && t.month == day.month && t.day == day.day;
      }).length;
      return (day: day, count: count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final data = _buckets();
    final maxCount = data.fold<int>(1, (m, e) => math.max(m, e.count));
    final total = data.fold<int>(0, (s, e) => s + e.count);

    // Son uc gun ile onceki uc gunu karsilastirarak basit bir egilim.
    final recent = data.skip(4).fold<int>(0, (s, e) => s + e.count);
    final earlier = data.take(3).fold<int>(0, (s, e) => s + e.count);
    final rising = recent >= earlier;

    final labels = strings.weekdayInitials();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                strings.t('weeklyTitle'),
                style: context.text.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (rising ? tokens.success : tokens.muted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: rising ? -1.5708 : 1.5708,
                      child: SoftIcon(
                        AppIcon.chevron,
                        size: 11,
                        color: rising ? tokens.success : tokens.muted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$total',
                      style: context.text.labelSmall?.copyWith(
                        color: rising ? tokens.success : tokens.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, bucket) in data.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _Bar(
                        ratio: bucket.count / maxCount,
                        count: bucket.count,
                        label: labels[bucket.day.weekday - 1],
                        highlight: i == data.length - 1,
                      ),
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
    // Sifir olan gunlerde de ince bir iz birakilir ki eksen okunabilsin.
    final height = 6 + ratio * 56;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count == 0 ? '' : '$count',
          style: context.text.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? AppPalette.brand : tokens.muted,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          height: height,
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFC084FC), Color(0xFFA855F7)],
                  )
                : null,
            color: highlight
                ? null
                : AppPalette.brand.withValues(alpha: count == 0 ? 0.10 : 0.26),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: highlight ? AppPalette.brand : tokens.muted,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Arayanlarin dil dagilimi: tek bir yatay seritte oranlar.
class LanguageMixCard extends StatelessWidget {
  const LanguageMixCard({super.key, required this.calls});

  final List<CallSummary> calls;

  static const _order = ['tr', 'ar', 'en'];
  static const _colors = {
    'tr': AppPalette.brand,
    'ar': AppPalette.mint,
    'en': AppPalette.violet,
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final counts = <String, int>{for (final k in _order) k: 0};
    for (final c in calls) {
      final key = _order.contains(c.lang) ? c.lang : 'tr';
      counts[key] = counts[key]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.t('langMixTitle'),
            style:
                context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? ColoredBox(color: tokens.glassBorder)
                  : Row(
                      children: [
                        for (final key in _order)
                          if (counts[key]! > 0)
                            Expanded(
                              flex: counts[key]!,
                              child: ColoredBox(color: _colors[key]!),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          for (final key in _order) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _colors[key],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      strings.t('lang_$key'),
                      style: context.text.bodySmall,
                    ),
                  ),
                  Text(
                    total == 0
                        ? '0%'
                        : '${((counts[key]! / total) * 100).round()}%',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: tokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tek bir buyuk rakam: en yogun saat.
class PeakHourCard extends StatelessWidget {
  const PeakHourCard({super.key, required this.calls});

  final List<CallSummary> calls;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

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

    final label = peak == null
        ? '—'
        : '${peak.toString().padLeft(2, '0')}:00';

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SoftIcon(AppIcon.clock, size: 16, color: tokens.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.t('peakHourTitle'),
                  maxLines: 2,
                  style: context.text.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            label,
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppPalette.brand,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            peak == null
                ? strings.t('peakHourEmpty')
                : '$best ${strings.t('peakHourUnit')}',
            style: context.text.bodySmall?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}
