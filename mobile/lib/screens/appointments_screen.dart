import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import 'call_detail_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final items = state.appointments;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('appointmentsTitle'))),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (state.isDemo) DemoBanner(onOpenSettings: onOpenSettings),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${strings.t('workHours')}: '
                      '${state.config.workStart} - ${state.config.workEnd}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.event_busy_outlined,
                title: strings.t('emptyAppointments'),
                message: strings.t('emptyAppointmentsHint'),
              )
            else
              for (final call in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CallDetailScreen(callId: call.callId),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                call.appointmentInfo
                                        .toLowerCase()
                                        .contains('i̇ptal') ||
                                        call.appointmentInfo
                                            .toLowerCase()
                                            .contains('iptal')
                                    ? Icons.event_busy_outlined
                                    : Icons.event_available_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    call.appointmentInfo,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    call.callerName.isEmpty
                                        ? strings.t('unnamed')
                                        : call.callerName,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.friendly(call.timestamp, strings),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: context.status.muted),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: context.status.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
