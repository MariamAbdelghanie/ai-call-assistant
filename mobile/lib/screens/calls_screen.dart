import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/app_header.dart';
import '../widgets/insights.dart';
import '../widgets/kpi_ring.dart';
import '../widgets/soft_icon.dart';
import 'call_detail_screen.dart';

enum CallFilter { all, urgent, callback, today }

/// Ana sayfa.
///
/// Duzen yukaridan asagiya tek bir oncelik sirasi izler: kim oldugun (selam),
/// sistem calisiyor mu (durum seridi), simdi ne yapabilirsin (eylem karti),
/// sayilar (tek satir ozet), sonra liste. Her blok farkli bir bicimde
/// oldugundan goz blok sinirlarini kolayca ayirir.
class CallsScreen extends StatefulWidget {
  const CallsScreen({
    super.key,
    required this.onOpenSettings,
    required this.onStartCall,
    required this.onOpenUrgent,
    required this.onOpenAppointments,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onStartCall;
  final VoidCallback onOpenUrgent;
  final VoidCallback onOpenAppointments;

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final TextEditingController _search = TextEditingController();
  CallFilter _filter = CallFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CallSummary> _apply(List<CallSummary> source) {
    final query = _search.text.trim().toLowerCase();
    return source.where((call) {
      final matchesFilter = switch (_filter) {
        CallFilter.all => true,
        CallFilter.urgent => call.isUrgent,
        CallFilter.callback => call.awaitingCallback,
        CallFilter.today => Formatters.isToday(call.timestamp),
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return call.callerName.toLowerCase().contains(query) ||
          call.summary.toLowerCase().contains(query) ||
          call.callerPurpose.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _openDetail(CallSummary call) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallDetailScreen(callId: call.callId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final visible = _apply(state.calls);

    final auth = AuthScope.of(context);
    final full = auth.displayName.trim();
    final first = full.isEmpty ? '' : full.split(RegExp(r'\s+')).first;
    final photo = auth.photoUrl;
    final total = state.calls.length;

    return AppHeaderScaffold(
      title: first.isEmpty
          ? strings.t('greetingTitle')
          : '${strings.t('greetingHi')}, $first!',
      subtitle: strings.t('greetingSubtitle'),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.22),
        foregroundImage: photo == null ? null : NetworkImage(photo),
        child: Text(
          first.isEmpty ? 'C' : first.characters.first.toUpperCase(),
          style: context.text.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      actions: [
        HeaderIconButton(
          icon: Icons.tune_rounded,
          onTap: widget.onOpenSettings,
          tooltip: strings.t('tabSettings'),
        ),
      ],
      headerChild: HeaderStatusStrip(
        label: strings.t(state.config.enabled ? 'assistantOn' : 'assistantOff'),
        hours: '${state.config.workStart} - ${state.config.workEnd}',
        online: state.config.enabled,
      ),
      overlap: 26,
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 112),
          children: [
            // Ozet halkalari turuncu bandin uzerine biniyor; sayfa bu
            // sayede baslikla govde arasinda bir basamakla basliyor.
            KpiRingRow(
              items: [
                KpiRing(
                  value: total,
                  total: total,
                  label: strings.t('statTotal'),
                  color: AppPalette.orange,
                ),
                KpiRing(
                  value: state.urgentCount,
                  total: total,
                  label: strings.t('statUrgent'),
                  color: AppPalette.urgent,
                  onTap: widget.onOpenUrgent,
                ),
                KpiRing(
                  value: state.appointments.length,
                  total: total,
                  label: strings.t('tabAppointments'),
                  color: AppPalette.scheduled,
                  onTap: widget.onOpenAppointments,
                ),
                KpiRing(
                  value: state.awaitingCount,
                  total: total,
                  label: strings.t('filterCallback'),
                  color: AppPalette.pending,
                  onTap: () => setState(() => _filter = CallFilter.callback),
                ),
              ],
            ),
            const SizedBox(height: 14),

            QuickActionPills(
              actions: [
                (
                  icon: Icons.call_rounded,
                  label: strings.t('quickTestCall'),
                  onTap: widget.onStartCall
                ),
                (
                  icon: Icons.event_rounded,
                  label: strings.t('quickAgenda'),
                  onTap: widget.onOpenAppointments
                ),
                (
                  icon: Icons.priority_high_rounded,
                  label: strings.t('quickUrgent'),
                  onTap: widget.onOpenUrgent
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (state.isDemo || state.isOffline) ...[
              DemoBanner(
                onOpenSettings: widget.onOpenSettings,
                offline: state.isOffline,
              ),
              const SizedBox(height: 12),
            ],

            _ActionCard(onStartCall: widget.onStartCall),
            const SizedBox(height: 14),

            WeeklyActivityCard(calls: state.calls),
            const SizedBox(height: 12),

            // Ikili satir: solda oranlar, sagda tek buyuk rakam. Farkli
            // yukseklikte iki kart yan yana durunca sayfanin ritmi kirilir.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: LanguageMixCard(calls: state.calls),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: PeakHourCard(calls: state.calls),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SectionTitle(strings.t('callsTitle')),
            const SizedBox(height: 4),
            _SearchField(
              controller: _search,
              hint: strings.t('search'),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in <(CallFilter, String)>[
                    (CallFilter.all, 'filterAll'),
                    (CallFilter.urgent, 'filterUrgent'),
                    (CallFilter.callback, 'filterCallback'),
                    (CallFilter.today, 'filterToday'),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: _Pill(
                        label: strings.t(entry.$2),
                        selected: _filter == entry.$1,
                        onTap: () => setState(() => _filter = entry.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (state.status == LoadStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              EmptyState(
                icon: AppIcon.inbox,
                title: strings.t('emptyCalls'),
                message: strings.t('emptyCallsHint'),
              )
            else
              // Tum satirlar tek bir beyaz yuzeyde: liste bir butun gibi
              // okunur, kart yigini gibi parcalanmaz.
              GlassCard(
                padding: EdgeInsets.zero,
                radius: 20,
                child: Column(
                  children: [
                    for (final (index, call) in visible.indexed) ...[
                      if (index > 0)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 72,
                          color: context.tokens.glassBorder,
                        ),
                      AnimatedEntrance(
                        index: index,
                        child: _CallRow(
                          call: call,
                          onTap: () => _openDetail(call),
                        ),
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

/// Test aramasini baslatan one cikan kart.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.onStartCall});

  final VoidCallback onStartCall;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStartCall,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppPalette.orange, Color(0xFFF08A3E)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppPalette.orange.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.t('heroCta'),
                      style: context.text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.t('heroTitle'),
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded,
                    color: AppPalette.orange, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: tokens.muted),
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
        filled: true,
        fillColor: tokens.isDark ? tokens.glass : AppPalette.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppTheme.fast,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.orange
                : (tokens.isDark ? tokens.glass : AppPalette.surface),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppPalette.orange : tokens.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: context.text.labelLarge?.copyWith(
              color: selected ? Colors.white : tokens.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.call, required this.onTap});

  final CallSummary call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final accent = call.isUrgent
        ? tokens.urgent
        : call.awaitingCallback
            ? tokens.pending
            : AppPalette.orange;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                Formatters.initials(call.callerName),
                style: context.text.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          call.callerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (call.isUrgent) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.bolt_rounded,
                            size: 15, color: tokens.urgent),
                      ],
                      if (call.hasAppointment) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.event_available_rounded,
                            size: 14, color: tokens.success),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    call.summary.trim().isEmpty
                        ? call.callerPurpose
                        : call.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        context.text.bodySmall?.copyWith(color: tokens.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.friendly(call.timestamp, strings),
                  style: context.text.labelSmall?.copyWith(color: tokens.muted),
                ),
                const SizedBox(height: 7),
                if (call.awaitingCallback)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: tokens.pending,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: tokens.glassBorder),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
