import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Haftalik takvim izgarasinda tek bir randevu.
class GridEvent {
  const GridEvent({
    required this.start,
    required this.title,
    required this.canceled,
    this.onTap,
  });

  final DateTime start;
  final String title;
  final bool canceled;
  final VoidCallback? onTap;
}

/// Hafta gorunumu: solda saatler, ustte gunler, icinde randevu bloklari.
///
/// Liste tek basina randevularin gunun neresine dustugunu gostermiyordu;
/// izgarada bos saatler de gorundugu icin "sali ogleden sonrasi bos"
/// bilgisi tek bakista okunuyor.
class WeekGrid extends StatelessWidget {
  const WeekGrid({
    super.key,
    required this.weekStart,
    required this.dayLabels,
    required this.events,
    this.startHour = 8,
    this.endHour = 20,
  });

  /// Gosterilen haftanin pazartesisi.
  final DateTime weekStart;

  /// Pazartesiden pazara gun kisaltmalari.
  final List<String> dayLabels;

  final List<GridEvent> events;

  /// Izgaranin kapsadigi saat araligi; mesai disi saatleri cizmiyoruz.
  final int startHour;
  final int endHour;

  static const double _hourHeight = 44;
  static const double _timeColumn = 42;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hours = endHour - startHour;
    final gridHeight = hours * _hourHeight;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: tokens.glass,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: tokens.glassBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        children: [
          // Gun basliklari.
          Row(
            children: [
              const SizedBox(width: _timeColumn),
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      dayLabels[i % dayLabels.length],
                      style: context.text.labelSmall?.copyWith(
                        color: tokens.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: gridHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columnWidth =
                    (constraints.maxWidth - _timeColumn) / 7;

                return Stack(
                  children: [
                    // Saat cizgileri ve etiketleri.
                    for (var h = 0; h <= hours; h++)
                      Positioned(
                        top: h * _hourHeight,
                        left: 0,
                        right: 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: _timeColumn,
                              child: Transform.translate(
                                offset: const Offset(0, -6),
                                child: Text(
                                  '${(startHour + h).toString().padLeft(2, '0')}:00',
                                  style: context.text.labelSmall?.copyWith(
                                    color: tokens.muted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: tokens.glassBorder,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Gun ayirici dikey cizgiler.
                    for (var d = 1; d < 7; d++)
                      Positioned(
                        left: _timeColumn + d * columnWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1,
                          color: tokens.glassBorder.withValues(alpha: 0.6),
                        ),
                      ),

                    // Randevu bloklari.
                    for (final event in events)
                      ..._blockFor(
                        context,
                        event,
                        columnWidth,
                        tokens,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Randevuyu izgaradaki yerine yerlestirir. Bu haftanin disinda ya da
  /// cizilen saat araliginin disinda kalanlar atlanir.
  List<Widget> _blockFor(
    BuildContext context,
    GridEvent event,
    double columnWidth,
    AppTokens tokens,
  ) {
    final dayIndex = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    ).difference(weekStart).inDays;
    if (dayIndex < 0 || dayIndex > 6) return const [];

    final minutes = event.start.hour * 60 + event.start.minute;
    final from = startHour * 60;
    final to = endHour * 60;
    if (minutes < from || minutes >= to) return const [];

    final top = (minutes - from) / 60 * _hourHeight;
    final color = event.canceled ? tokens.muted : AppPalette.scheduled;

    return [
      Positioned(
        left: _timeColumn + dayIndex * columnWidth + 2,
        width: columnWidth - 4,
        top: top,
        height: _hourHeight - 4,
        child: GestureDetector(
          onTap: event.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
              border: Border(
                left: BorderSide(color: color, width: 2.5),
              ),
            ),
            child: Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                decoration:
                    event.canceled ? TextDecoration.lineThrough : null,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
