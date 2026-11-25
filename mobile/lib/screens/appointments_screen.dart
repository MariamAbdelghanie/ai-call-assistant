import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/week_grid.dart';
import '../widgets/glass.dart';
import '../widgets/soft_icon.dart';
import 'call_detail_screen.dart';

/// Randevular ekrani.
///
/// Liste yerine dikey bir zaman cizgisi kullanilir: solda saat, ortada
/// cizgi ve nokta, sagda kart. Boylece randevular bir takvim gibi okunur ve
/// ekran diger sayfalarin tekrari olmaktan cikar.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();

  /// `2026-11-19 17:00 (Sebep)` bicimindeki metni parcalara ayirir.
  static ({DateTime? when, String title}) _parse(String info) {
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

  static bool _isCanceled(String info) {
    final lower = info.toLowerCase();
    return lower.contains('iptal') || lower.contains('i̇ptal');
  }

  /// Ayni kisi ve ayni saat icin sonradan bir iptal kaydi varsa, randevunun
  /// alindigi kayit da iptal sayilir. Aksi halde listede ayni randevu hem
  /// aktif hem iptal gorunuyor ve hangisinin gecerli oldugu anlasilmiyordu.
  static bool _canceledLater(List<CallSummary> all, CallSummary call) {
    final mine = _parse(call.appointmentInfo).when;
    if (mine == null) return false;
    return all.any((other) {
      if (other.callId == call.callId) return false;
      if (!_isCanceled(other.appointmentInfo)) return false;
      if (other.callerName.trim().toLowerCase() !=
          call.callerName.trim().toLowerCase()) {
        return false;
      }
      return _parse(other.appointmentInfo).when == mine;
    });
  }
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  /// Gosterilen haftanin pazartesisi.
  DateTime _weekStart = _mondayOf(DateTime.now());

  /// Secili gun; null ise tum randevular listelenir.
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

    // Zaman sirasina diz; tarihi okunamayanlar sona alinir.
    final items = [...state.appointments]..sort((a, b) {
        final x = AppointmentsScreen._parse(a.appointmentInfo).when;
        final y = AppointmentsScreen._parse(b.appointmentInfo).when;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return x.compareTo(y);
      });

    final shown = _selected == null
        ? items
        : items.where((call) {
            final when = AppointmentsScreen._parse(call.appointmentInfo).when;
            return when != null && _sameDay(when, _selected!);
          }).toList();

    final weekEnd = _weekStart.add(const Duration(days: 6));

    return AppHeaderScaffold(
      title: strings.t('appointmentsTitle'),
      subtitle: '${items.length} ${strings.t('appointmentsCount')} · '
          '${state.config.workStart} - ${state.config.workEnd}',
      actions: [
        if (_selected != null)
          HeaderIconButton(
            icon: Icons.close_rounded,
            onTap: () => setState(() => _selected = null),
            tooltip: strings.t('filterAll'),
          ),
      ],
      headerChild: HeaderWeekStrip(
        weekStart: _weekStart,
        selected: _selected,
        dayLabels: [
          for (final key in const [
            'dayMon',
            'dayTue',
            'dayWed',
            'dayThu',
            'dayFri',
            'daySat',
            'daySun',
          ])
            strings.t(key),
        ],
        hasItems: (day) => items.any((call) {
          final when = AppointmentsScreen._parse(call.appointmentInfo).when;
          return when != null && _sameDay(when, day);
        }),
        onSelect: (day) => setState(() {
          _selected =
              (_selected != null && _sameDay(_selected!, day)) ? null : day;
        }),
        onPrevWeek: () => setState(() {
          _weekStart = _weekStart.subtract(const Duration(days: 7));
        }),
        onNextWeek: () => setState(() {
          _weekStart = _weekStart.add(const Duration(days: 7));
        }),
        rangeLabel:
            '${Formatters.date(_weekStart)} - ${Formatters.date(weekEnd)}',
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
          children: [
            if (state.isDemo || state.isOffline) ...[
              DemoBanner(
                onOpenSettings: widget.onOpenSettings,
                offline: state.isOffline,
              ),
              const SizedBox(height: 14),
            ],
            // Hafta izgarasi: randevularin gunun neresine dustugunu ve
            // hangi saatlerin bos oldugunu gosterir.
            WeekGrid(
              weekStart: _weekStart,
              dayLabels: [
                for (final key in const [
                  'dayMon',
                  'dayTue',
                  'dayWed',
                  'dayThu',
                  'dayFri',
                  'daySat',
                  'daySun',
                ])
                  strings.t(key),
              ],
              events: [
                for (final call in items)
                  if (AppointmentsScreen._parse(call.appointmentInfo).when
                      case final startsAt?)
                    GridEvent(
                      start: startsAt,
                      title: call.callerName,
                      canceled: AppointmentsScreen._isCanceled(
                              call.appointmentInfo) ||
                          AppointmentsScreen._canceledLater(items, call),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CallDetailScreen(callId: call.callId),
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 20),

            SectionTitle(strings.t('appointmentsTitle')),
            const SizedBox(height: 10),

            if (shown.isEmpty)
              EmptyState(
                icon: AppIcon.calendar,
                title: strings.t('emptyAppointments'),
                message: strings.t('emptyAppointmentsHint'),
              )
            else
              for (final (index, call) in shown.indexed)
                _TimelineRow(
                  call: call,
                  parsed: AppointmentsScreen._parse(call.appointmentInfo),
                  canceled:
                      AppointmentsScreen._isCanceled(call.appointmentInfo) ||
                          AppointmentsScreen._canceledLater(items, call),
                  isFirst: index == 0,
                  isLast: index == shown.length - 1,
                  // Gun degistiginde tarih basligi gosterilir.
                  dayLabel: _dayLabelFor(shown, index, strings),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CallDetailScreen(callId: call.callId),
                    ),
                  ),
                ),
            if (shown.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  strings.t('timelineEnd'),
                  style: context.text.labelSmall?.copyWith(color: tokens.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Onceki ogeden farkli bir gune geciliyorsa gun basligi doner.
String? _dayLabelFor(
  List<CallSummary> items,
  int index,
  AppStrings strings,
) {
  final current = AppointmentsScreen._parse(items[index].appointmentInfo).when;
  if (current == null) return null;
  if (index == 0) return _humanDay(current, strings);
  final previous =
      AppointmentsScreen._parse(items[index - 1].appointmentInfo).when;
  if (previous == null) return _humanDay(current, strings);
  final sameDay = previous.year == current.year &&
      previous.month == current.month &&
      previous.day == current.day;
  return sameDay ? null : _humanDay(current, strings);
}

String _humanDay(DateTime value, AppStrings strings) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return strings.t('today');
  if (diff == 1) return strings.t('tomorrow');
  return Formatters.date(value);
}

/// Zaman cizgisinin tek bir satiri.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.call,
    required this.parsed,
    required this.canceled,
    required this.isFirst,
    required this.isLast,
    required this.dayLabel,
    required this.onTap,
  });

  final CallSummary call;
  final ({DateTime? when, String title}) parsed;
  final bool canceled;
  final bool isFirst;
  final bool isLast;
  final String? dayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = canceled ? tokens.muted : AppPalette.ink;
    final time = parsed.when == null ? '--:--' : Formatters.time(parsed.when!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dayLabel != null)
          Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 14, bottom: 10),
            child: Row(
              children: [
                Text(
                  dayLabel!,
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: tokens.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(height: 1, color: tokens.glassBorder),
                ),
              ],
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saat sutunu
              SizedBox(
                width: 46,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    time,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: canceled ? tokens.muted : null,
                      decoration: canceled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
              // Cizgi ve nokta
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: 14,
                      color: isFirst ? Colors.transparent : tokens.glassBorder,
                    ),
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: canceled ? Colors.transparent : accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2.2),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : tokens.glassBorder,
                      ),
                    ),
                  ],
                ),
              ),
              // Kart
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    radius: 16,
                    onTap: onTap,
                    borderColor:
                        canceled ? null : accent.withValues(alpha: 0.30),
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
                                style: context.text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: canceled
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: canceled ? tokens.muted : null,
                                ),
                              ),
                            ),
                            SoftIcon(
                              canceled
                                  ? AppIcon.calendarOff
                                  : AppIcon.calendarOk,
                              size: 16,
                              color: accent,
                              solid: true,
                            ),
                          ],
                        ),
                        if (parsed.title.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            parsed.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall
                                ?.copyWith(color: tokens.muted, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
