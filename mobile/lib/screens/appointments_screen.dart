import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/soft_icon.dart';
import 'call_detail_screen.dart';

/// Randevular ekrani.
///
/// Ustte ay ve hafta seridi, altinda randevular gune gore grupluyor. Saat
/// solda, ad ve sebep sagda; boylece gun icinde gozun takip edecegi tek bir
/// dikey cizgi oluyor.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  /// `2026-11-19 17:00 (Sebep)` bicimindeki metni parcalara ayirir.
  static ({DateTime? when, String title}) parse(String info) {
    final match =
        RegExp(r'(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})').firstMatch(info);
    DateTime? when;
    if (match != null) {
      when = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
      );
    }
    final paren = RegExp(r'\(([^)]+)\)').firstMatch(info);
    return (when: when, title: (paren?.group(1) ?? '').trim());
  }

  static bool isCanceled(String info) {
    final lower = info.toLowerCase();
    return lower.contains('iptal') || lower.contains('i̇ptal');
  }

  /// Ayni kisi ve ayni saat icin sonradan bir iptal kaydi varsa, randevunun
  /// alindigi kayit da iptal sayilir.
  static bool canceledLater(List<CallSummary> all, CallSummary call) {
    final mine = parse(call.appointmentInfo).when;
    if (mine == null) return false;
    return all.any((other) {
      if (other.callId == call.callId) return false;
      if (!isCanceled(other.appointmentInfo)) return false;
      if (other.callerName.trim().toLowerCase() !=
          call.callerName.trim().toLowerCase()) {
        return false;
      }
      return parse(other.appointmentInfo).when == mine;
    });
  }

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _weekStart = _mondayOf(DateTime.now());

  /// Secili gun; null ise haftanin tamami listelenir.
  DateTime? _selected;

  static DateTime _mondayOf(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final items = [...state.appointments]..sort((a, b) {
        final x = AppointmentsScreen.parse(a.appointmentInfo).when;
        final y = AppointmentsScreen.parse(b.appointmentInfo).when;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });

    final weekEnd = _weekStart.add(const Duration(days: 7));
    bool inWeek(DateTime d) =>
        !d.isBefore(_weekStart) && d.isBefore(weekEnd);

    final weekItems = items.where((call) {
      final when = AppointmentsScreen.parse(call.appointmentInfo).when;
      return when != null && inWeek(when);
    }).toList();

    final shown = _selected == null
        ? weekItems
        : weekItems.where((call) {
            final when = AppointmentsScreen.parse(call.appointmentInfo).when;
            return when != null && _sameDay(when, _selected!);
          }).toList();

    final pending = weekItems
        .where((c) => AppointmentsScreen.parse(c.appointmentInfo).title
            .toLowerCase()
            .contains('talep'))
        .length;

    // Gune gore gruplama: her gun bir baslik, altinda o gunun satirlari.
    final groups = <DateTime, List<CallSummary>>{};
    for (final call in shown) {
      final when = AppointmentsScreen.parse(call.appointmentInfo).when;
      if (when == null) continue;
      final key = DateTime(when.year, when.month, when.day);
      groups.putIfAbsent(key, () => []).add(call);
    }
    final days = groups.keys.toList()..sort();

    return PageScaffold(
      title: strings.t('appointmentsTitle'),
      subtitle: '${strings.t('appointmentsThisWeek')} ${weekItems.length} '
          '${strings.t('appointmentsCount')}'
          '${pending > 0 ? ' · $pending ${strings.t('awaitingApproval')}' : ''}',
      onRefresh: state.refresh,
      children: [
        if (state.isDemo || state.isOffline) ...[
          DemoBanner(
            onOpenSettings: widget.onOpenSettings,
            offline: state.isOffline,
          ),
          const SizedBox(height: 14),
        ],

        _WeekPicker(
          weekStart: _weekStart,
          selected: _selected,
          monthLabel: Formatters.monthYear(_weekStart, strings),
          dayLabels: strings.weekdayInitials(),
          hasItems: (day) => items.any((call) {
            final when = AppointmentsScreen.parse(call.appointmentInfo).when;
            return when != null && _sameDay(when, day);
          }),
          onSelect: (day) => setState(() {
            _selected =
                (_selected != null && _sameDay(_selected!, day)) ? null : day;
          }),
          onPrev: () => setState(() {
            _weekStart = _weekStart.subtract(const Duration(days: 7));
            _selected = null;
          }),
          onNext: () => setState(() {
            _weekStart = _weekStart.add(const Duration(days: 7));
            _selected = null;
          }),
        ),
        const SizedBox(height: 22),

        if (shown.isEmpty)
          EmptyState(
            icon: AppIcon.calendar,
            title: strings.t('emptyAppointments'),
            message: strings.t('emptyAppointmentsHint'),
          )
        else
          for (final day in days) ...[
            SectionLabel(
              '${strings.weekdayNames()[day.weekday - 1]}, '
              '${Formatters.dayMonth(day, strings)}',
            ),
            for (final call in groups[day]!)
              _AppointmentRow(
                call: call,
                canceled:
                    AppointmentsScreen.isCanceled(call.appointmentInfo) ||
                        AppointmentsScreen.canceledLater(items, call),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CallDetailScreen(callId: call.callId),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

        if (shown.isNotEmpty)
          Center(
            child: Text(
              strings.t('timelineEnd'),
              style: context.text.labelSmall?.copyWith(color: tokens.muted),
            ),
          ),
      ],
    );
  }
}

/// Ay basligi, oklar ve yedi gunluk serit.
class _WeekPicker extends StatelessWidget {
  const _WeekPicker({
    required this.weekStart,
    required this.selected,
    required this.monthLabel,
    required this.dayLabels,
    required this.hasItems,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime weekStart;
  final DateTime? selected;
  final String monthLabel;
  final List<String> dayLabels;
  final bool Function(DateTime) hasItems;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            Text(
              monthLabel,
              style:
                  context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left_rounded),
              color: tokens.muted,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              color: tokens.muted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
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
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 6),
          // Secili gun dolu turuncu, bugun yalnizca cerceveli: ikisi ayni
          // anda gorunur ama birbirine karismaz.
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppPalette.orange : Colors.transparent,
              shape: BoxShape.circle,
              border: (!selected && isToday)
                  ? Border.all(color: AppPalette.orange, width: 1.6)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: context.text.titleSmall?.copyWith(
                color: selected
                    ? Colors.white
                    : (isToday ? AppPalette.orange : null),
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: marked ? AppPalette.orange : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek randevu satiri: solda saat, sagda ad ve durum.
class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.call,
    required this.canceled,
    required this.onTap,
  });

  final CallSummary call;
  final bool canceled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final parsed = AppointmentsScreen.parse(call.appointmentInfo);
    final when = parsed.when;
    final color = canceled ? tokens.muted : AppPalette.scheduled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Text(
                when == null ? '—' : Formatters.time(when),
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: canceled ? tokens.muted : null,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  decoration: canceled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              width: 3,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    call.callerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: canceled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parsed.title.isEmpty
                        ? call.callerPurpose
                        : parsed.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: canceled ? tokens.muted : color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              canceled ? Icons.event_busy_rounded : Icons.event_available_rounded,
              size: 18,
              color: canceled ? tokens.muted : tokens.success,
            ),
          ],
        ),
      ),
    );
  }
}
