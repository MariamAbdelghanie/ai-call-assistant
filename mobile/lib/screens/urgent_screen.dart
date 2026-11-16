import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/common.dart';
import 'call_detail_screen.dart';

class UrgentScreen extends StatelessWidget {
  const UrgentScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final urgent = state.urgentCalls;

    return GlassScaffold(
      title: strings.t('urgentTitle'),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
          children: [
            if (state.isDemo) DemoBanner(onOpenSettings: onOpenSettings),
            if (urgent.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.tokens.urgentSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: context.tokens.urgent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.tokens.urgent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: context.tokens.urgent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${urgent.length}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.tokens.urgent,
                            ),
                          ),
                          Text(
                            strings.t('urgentTitle'),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: context.tokens.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (urgent.isEmpty)
              EmptyState(
                icon: Icons.verified_outlined,
                title: strings.t('emptyUrgent'),
                message: strings.t('emptyUrgentHint'),
              )
            else
              for (final call in urgent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CallCard(
                    call: call,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CallDetailScreen(callId: call.callId),
                      ),
                    ),
                    onToggleCalledBack: () => state.toggleCalledBack(call),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
