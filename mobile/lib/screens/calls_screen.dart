import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/home_parts.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/soft_icon.dart';
import 'call_detail_screen.dart';

/// Ana sayfa.
///
/// Sira sabit: kim oldugun (selam), asistan calisiyor mu, bugunun sayilari,
/// haftanin grafigi, sonra son cagrilar. Arama kutusu en uste alindi;
/// listede bir ad aramak en sik yapilan is.
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

  /// Arama yapilmadiginda liste kisa tutulur; tamami "Tumunu gor" ile acilir.
  bool _showAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CallSummary> _apply(List<CallSummary> source) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((call) {
      return call.callerName.toLowerCase().contains(query) ||
          call.summary.toLowerCase().contains(query) ||
          call.callerPurpose.toLowerCase().contains(query);
    }).toList();
  }

  void _openDetail(CallSummary call) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CallDetailScreen(callId: call.callId),
      ),
    );
  }

  Future<void> _toggleAssistant(AppState state, bool value) async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await state.saveConfig(state.config.copyWith(enabled: value));
    messenger.showSnackBar(
      SnackBar(content: Text(strings.t(ok ? 'saved' : 'loadError'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final auth = AuthScope.of(context);

    final full = auth.displayName.trim();
    final first = full.isEmpty ? '' : full.split(RegExp(r'\s+')).first;
    final searching = _search.text.trim().isNotEmpty;
    final matched = _apply(state.calls);
    final visible =
        (searching || _showAll) ? matched : matched.take(5).toList();

    return PageScaffold(
      title: first.isEmpty
          ? strings.t('greetingTitle')
          : '${strings.t('greetingHi')}, $first',
      subtitle: Formatters.longDate(DateTime.now(), strings),
      onRefresh: state.refresh,
      topBar: HomeSearchBar(
        controller: _search,
        onChanged: () => setState(() {}),
        initials: first.isEmpty ? 'C' : first.characters.first.toUpperCase(),
        photoUrl: auth.photoUrl,
        onProfile: widget.onOpenSettings,
      ),
      floating: ActionPillButton(
        icon: Icons.call_rounded,
        label: strings.t('quickTestCall'),
        onTap: widget.onStartCall,
      ),
      children: [
        if (state.isDemo || state.isOffline) ...[
          DemoBanner(
            onOpenSettings: widget.onOpenSettings,
            offline: state.isOffline,
          ),
          const SizedBox(height: 14),
        ],

        AssistantCard(
          enabled: state.config.enabled,
          hours: '${state.config.workStart} - ${state.config.workEnd}',
          onChanged: (value) => _toggleAssistant(state, value),
        ),
        const SizedBox(height: 18),

        StatStrip(
          items: [
            (
              value: state.calls.length,
              label: strings.t('statTotal'),
              color: tokens.isDark ? AppPalette.darkText : AppPalette.ink,
              onTap: null
            ),
            (
              value: state.urgentCount,
              label: strings.t('statUrgent'),
              color: tokens.urgent,
              onTap: widget.onOpenUrgent
            ),
            (
              value: state.appointments.length,
              label: strings.t('statAppointment'),
              color: AppPalette.scheduled,
              onTap: widget.onOpenAppointments
            ),
            (
              value: state.awaitingCount,
              label: strings.t('filterCallback'),
              color: tokens.pending,
              onTap: null
            ),
          ],
        ),
        const SizedBox(height: 18),

        WeekBars(calls: state.calls),
        const SizedBox(height: 22),

        SectionLabel(
          searching ? strings.t('callsTitle') : strings.t('recentCalls'),
          trailing: (searching || matched.length <= 5)
              ? null
              : GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? strings.t('filterAll') : strings.t('seeAll'),
                    style: context.text.labelMedium?.copyWith(
                      color: tokens.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),

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
          CardGroup(
            children: [
              for (final call in visible)
                CallRow(call: call, onTap: () => _openDetail(call)),
            ],
          ),
      ],
    );
  }
}
