import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/insights.dart';
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

    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 112),
            children: [
              _Greeting(onOpenSettings: widget.onOpenSettings),
              const SizedBox(height: 16),

              if (state.isDemo || state.isOffline) ...[
                DemoBanner(
                  onOpenSettings: widget.onOpenSettings,
                  offline: state.isOffline,
                ),
                const SizedBox(height: 12),
              ],

              _StatusStrip(
                enabled: state.config.enabled,
                workHours:
                    '${state.config.workStart} - ${state.config.workEnd}',
              ),
              const SizedBox(height: 12),

              _ActionCard(onStartCall: widget.onStartCall),
              const SizedBox(height: 14),

              _StatsBar(
                cells: [
                  (AppIcon.inbox, AppPalette.brand, '${state.calls.length}',
                      strings.t('statTotal'), null),
                  (
                    AppIcon.urgent,
                    AppPalette.urgent,
                    '${state.urgentCount}',
                    strings.t('statUrgent'),
                    widget.onOpenUrgent
                  ),
                  (
                    AppIcon.calendar,
                    AppPalette.violet,
                    '${state.appointments.length}',
                    strings.t('tabAppointments'),
                    widget.onOpenAppointments
                  ),
                  (
                    AppIcon.phoneBack,
                    AppPalette.pending,
                    '${state.awaitingCount}',
                    strings.t('filterCallback'),
                    () => setState(() => _filter = CallFilter.callback)
                  ),
                ],
              ),
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
      ),
    );
  }
}

/// Ust selamlama satiri.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Row(
      children: [
        const AssistantAvatar(size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.t('greetingTitle'), style: context.text.titleLarge),
              const SizedBox(height: 2),
              Text(
                strings.t('greetingSubtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall
                    ?.copyWith(color: context.tokens.muted),
              ),
            ],
          ),
        ),
        _CircleButton(icon: AppIcon.settings, onTap: onOpenSettings),
      ],
    );
  }
}

/// Beyaz, dairesel kucuk dugme.
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final AppIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
      shape: CircleBorder(side: BorderSide(color: tokens.glassBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: SoftIcon(icon, size: 20, color: tokens.muted),
        ),
      ),
    );
  }
}

/// Asistanin acik olup olmadigini ve mesai araligini tek satirda gosterir.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.enabled, required this.workHours});

  final bool enabled;
  final String workHours;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final color = enabled ? tokens.success : tokens.muted;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            strings.t(enabled ? 'heroOn' : 'heroOff'),
            style: context.text.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          SoftIcon(AppIcon.clock, size: 15, color: tokens.muted),
          const SizedBox(width: 6),
          Text(
            workHours,
            style: context.text.bodySmall?.copyWith(color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

/// Birincil eylem: solda metin, sagda buyuk yuvarlak arama dugmesi.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.onStartCall});

  final VoidCallback onStartCall;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onStartCall,
        child: Ink(
          decoration: BoxDecoration(
            gradient: context.tokens.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppPalette.brand.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SoftIcon(AppIcon.phone,
                      size: 24, color: AppPalette.brand, solid: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dort sayiyi tek bir beyaz serit icinde yan yana gosterir.
class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.cells});

  final List<(AppIcon, Color, String, String, VoidCallback?)> cells;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      radius: 20,
      child: Row(
        children: [
          for (final (i, cell) in cells.indexed) ...[
            if (i > 0)
              Container(width: 1, height: 38, color: tokens.glassBorder),
            Expanded(
              child: InkWell(
                onTap: cell.$5,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SoftIcon(cell.$1, size: 19, color: cell.$2, solid: true),
                      const SizedBox(height: 7),
                      Text(
                        cell.$3,
                        style: context.text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        cell.$4,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.text.labelSmall
                            ?.copyWith(color: tokens.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Arama alani.
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      radius: 16,
      child: Row(
        children: [
          SoftIcon(AppIcon.search, size: 18, color: tokens.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                hintStyle: context.text.bodyMedium?.copyWith(color: tokens.muted),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SoftIcon(AppIcon.close, size: 16, color: tokens.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Filtre hapi.
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
    return Material(
      color: selected
          ? AppPalette.brand
          : (tokens.isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : tokens.glassBorder,
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

/// Liste satiri: bas harfler, isim, ozet, saat ve durum noktasi.
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
            : AppPalette.brand;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                Formatters.initials(call.callerName),
                style: context.text.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                        SoftIcon(AppIcon.urgent,
                            size: 13, color: tokens.urgent, solid: true),
                      ],
                      if (call.hasAppointment) ...[
                        const SizedBox(width: 6),
                        SoftIcon(AppIcon.calendar,
                            size: 13, color: AppPalette.violet, solid: true),
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
                    style: context.text.bodySmall?.copyWith(color: tokens.muted),
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
                  SoftIcon(AppIcon.chevron, size: 14, color: tokens.glassBorder),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
