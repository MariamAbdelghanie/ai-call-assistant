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
  const CallsScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

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
                  color: context.status.urgent,
                  icon: Icons.priority_high_rounded,
                ),
                const SizedBox(width: 10),
                StatTile(
                  value: state.awaitingCount,
                  label: strings.t('statWaiting'),
                  color: context.status.accent,
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
