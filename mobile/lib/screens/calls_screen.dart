import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import 'call_detail_screen.dart';

enum CallFilter { all, urgent, callback, today }

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
    final tokens = context.tokens;
    final visible = _apply(state.calls);
    final recent = state.calls.take(6).toList(growable: false);

    return GlassScaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
            children: [
              _Greeting(onOpenSettings: widget.onOpenSettings),
              const SizedBox(height: 18),
              if (state.isDemo) ...[
                DemoBanner(onOpenSettings: widget.onOpenSettings),
                const SizedBox(height: 4),
              ],
              _HeroCard(
                enabled: state.config.enabled,
                workHours:
                    '${state.config.workStart} - ${state.config.workEnd}',
                onStartCall: widget.onStartCall,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.summarize_rounded,
                      label: strings.t('tabCalls'),
                      value: '${state.calls.length}',
                      color: AppPalette.brand,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.event_rounded,
                      label: strings.t('tabAppointments'),
                      value: '${state.appointments.length}',
                      color: AppPalette.brandLight,
                      onTap: widget.onOpenAppointments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.bolt_rounded,
                      label: strings.t('tabUrgent'),
                      value: '${state.urgentCount}',
                      color: tokens.urgent,
                      onTap: widget.onOpenUrgent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.phone_callback_rounded,
                      label: strings.t('statWaiting'),
                      value: '${state.awaitingCount}',
                      color: tokens.pending,
                      onTap: () =>
                          setState(() => _filter = CallFilter.callback),
                    ),
                  ),
                ],
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 22),
                SectionTitle(strings.t('recentCallers')),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) =>
                        _CallerChip(call: recent[index], onTap: _openDetail),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SectionTitle(strings.t('callsTitle')),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: strings.t('search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
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
                        child: ChoiceChip(
                          label: Text(strings.t(entry.$2)),
                          selected: _filter == entry.$1,
                          labelStyle: TextStyle(
                            color: _filter == entry.$1
                                ? Colors.white
                                : context.scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _filter = entry.$1),
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
                  icon: Icons.inbox_rounded,
                  title: strings.t('emptyCalls'),
                  message: strings.t('emptyCallsHint'),
                )
              else
                for (final (index, call) in visible.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AnimatedEntrance(
                      index: index,
                      child: CallCard(
                        call: call,
                        onTap: () => _openDetail(call),
                        onToggleCalledBack: () => state.toggleCalledBack(call),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

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
              Text(
                strings.t('greetingTitle'),
                style: context.text.titleLarge,
              ),
              Text(
                strings.t('greetingSubtitle'),
                style: context.text.bodySmall
                    ?.copyWith(color: context.tokens.muted),
              ),
            ],
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(10),
          radius: 999,
          onTap: onOpenSettings,
          child: const Icon(Icons.tune_rounded, size: 20),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.enabled,
    required this.workHours,
    required this.onStartCall,
  });

  final bool enabled;
  final String workHours;
  final VoidCallback onStartCall;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    return GlassCard(
      blur: true,
      strong: true,
      gradient: tokens.softGradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled ? tokens.successSoft : tokens.urgentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: enabled ? tokens.success : tokens.urgent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      strings.t(enabled ? 'heroOn' : 'heroOff'),
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled ? tokens.success : tokens.urgent,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const AssistantAvatar(size: 52),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            strings.t('heroTitle'),
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '${strings.t('workHours')} · $workHours',
            style: context.text.bodySmall?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: strings.t('heroCta'),
            icon: Icons.call_rounded,
            onTap: onStartCall,
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusSm,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: 14),
          Text(value, style: context.text.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall
                ?.copyWith(color: context.tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _CallerChip extends StatelessWidget {
  const _CallerChip({required this.call, required this.onTap});

  final CallSummary call;
  final void Function(CallSummary) onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final color = call.isUrgent ? tokens.urgent : AppPalette.brand;

    return SizedBox(
      width: 64,
      child: GestureDetector(
        onTap: () => onTap(call),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.glassStrong,
                    border: Border.all(color: color.withValues(alpha: 0.6),
                        width: 1.6),
                  ),
                  child: Text(
                    Formatters.initials(call.callerName),
                    style: context.text.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (call.awaitingCallback)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: tokens.pending,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tokens.isDark
                              ? const Color(0xFF221B3A)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              call.callerName.isEmpty
                  ? strings.t('unnamed')
                  : call.callerName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.labelSmall?.copyWith(color: tokens.muted),
            ),
          ],
        ),
      ),
    );
  }
}
