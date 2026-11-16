import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'call_detail_screen.dart';

enum CallFilter { all, urgent, callback, today }

class CallsScreen extends StatefulWidget {
  const CallsScreen({
    super.key,
    required this.onOpenSettings,
    required this.onStartCall,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onStartCall;

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

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final visible = _apply(state.calls);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('callsTitle')),
        actions: [
          IconButton(
            tooltip: strings.t('refresh'),
            onPressed: state.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (state.isDemo)
              DemoBanner(onOpenSettings: widget.onOpenSettings),
            _AssistantHero(
              enabled: state.config.enabled,
              workHours:
                  '${state.config.workStart} - ${state.config.workEnd}',
              onStartCall: widget.onStartCall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatTile(
                  value: state.calls.length,
                  label: strings.t('statTotal'),
                  color: theme.colorScheme.primary,
                  icon: Icons.forum_outlined,
                ),
                const SizedBox(width: 10),
                StatTile(
                  value: state.urgentCount,
                  label: strings.t('statUrgent'),
                  color: context.tokens.urgent,
                  icon: Icons.priority_high_rounded,
                ),
                const SizedBox(width: 10),
                StatTile(
                  value: state.awaitingCount,
                  label: strings.t('statWaiting'),
                  color: context.tokens.pending,
                  icon: Icons.phone_callback_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _filter = entry.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.status == LoadStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              EmptyState(
                icon: Icons.inbox_outlined,
                title: strings.t('emptyCalls'),
                message: strings.t('emptyCallsHint'),
              )
            else
              for (final call in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CallCard(
                    call: call,
                    onTap: () => _openDetail(context, call),
                    onToggleCalledBack: () => _toggle(context, state, call),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, CallSummary call) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallDetailScreen(callId: call.callId),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    AppState state,
    CallSummary call,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    final ok = await state.toggleCalledBack(call);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.t('loadError'))),
      );
    }
  }
}

/// Ustteki marka karti: asistanin durumu ve hizli arama dugmesi.
class _AssistantHero extends StatelessWidget {
  const _AssistantHero({
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: tokens.brandGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        boxShadow: [
          BoxShadow(color: tokens.glow, blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: enabled
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCA5A5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      strings.t(enabled ? 'heroOn' : 'heroOff'),
                      style: context.text.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            strings.t('heroTitle'),
            style: context.text.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${strings.t('workHours')} · $workHours',
            style: context.text.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppPalette.brandDeep,
              ),
              onPressed: onStartCall,
              icon: const Icon(Icons.call_rounded, size: 19),
              label: Text(strings.t('heroCta')),
            ),
          ),
        ],
      ),
    );
  }
}
