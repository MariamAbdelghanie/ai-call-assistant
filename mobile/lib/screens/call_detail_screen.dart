import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';

class CallDetailScreen extends StatelessWidget {
  const CallDetailScreen({super.key, required this.callId});

  final String callId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    final matches = state.calls.where((c) => c.callId == callId);
    if (matches.isEmpty) {
      return GlassScaffold(
        title: strings.t('detailTitle'),
        body: EmptyState(
          icon: Icons.inbox_outlined,
          title: strings.t('emptyCalls'),
          message: strings.t('emptyCallsHint'),
        ),
      );
    }
    final call = matches.first;

    return GlassScaffold(
      title: strings.t('detailTitle'),
      actions: [
        IconButton(
          tooltip: strings.t('delete'),
          icon: Icon(Icons.delete_outline_rounded, color: tokens.urgent),
          onPressed: () => _confirmDelete(context, state, call),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (call.isUrgent
                          ? tokens.urgent
                          : theme.colorScheme.primary)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  Formatters.initials(call.callerName),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: call.isUrgent
                        ? tokens.urgent
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.callerName.isEmpty
                          ? strings.t('unnamed')
                          : call.callerName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.friendly(call.timestamp, strings),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: tokens.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (call.isUrgent)
                StatusBadge(
                  label: strings.t('urgentBadge'),
                  foreground: tokens.urgent,
                  background: tokens.urgentSoft,
                  icon: Icons.priority_high_rounded,
                ),
              if (call.awaitingCallback)
                StatusBadge(
                  label: strings.t('callbackBadge'),
                  foreground: tokens.pending,
                  background: tokens.pendingSoft,
                  icon: Icons.phone_callback_outlined,
                ),
              if (call.calledBack)
                StatusBadge(
                  label: strings.t('calledBack'),
                  foreground: tokens.success,
                  background: tokens.successSoft,
                  icon: Icons.check_circle_outline,
                ),
              StatusBadge(
                label: strings.languageName(call.lang),
                foreground: tokens.muted,
                background: tokens.muted.withValues(alpha: 0.12),
                icon: Icons.translate_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: strings.t('summary'),
            child: SelectableText(
              call.summary.isEmpty ? '—' : call.summary,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ),
          if (call.callerPurpose.isNotEmpty)
            _Section(
              title: strings.t('callerPurpose'),
              child: Text(call.callerPurpose,
                  style: theme.textTheme.bodyLarge),
            ),
          if (call.hasAppointment)
            _Section(
              title: strings.t('appointment'),
              child: Row(
                children: [
                  Icon(Icons.event_available_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      call.appointmentInfo,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          _Section(
            title: strings.t('callerNumber'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    call.callerNumber.isEmpty ? '—' : call.callerNumber,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (call.callerNumber.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: call.callerNumber),
                      );
                      messenger.showSnackBar(
                        SnackBar(content: Text(strings.t('copied'))),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(strings.t('copyNumber')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (call.callbackRequested)
            SizedBox(
              width: double.infinity,
              child: call.calledBack
                  ? OutlinedButton.icon(
                      onPressed: () => state.toggleCalledBack(call),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: Text(strings.t('markNotCalledBack')),
                    )
                  : FilledButton.icon(
                      onPressed: () => state.toggleCalledBack(call),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(strings.t('markCalledBack')),
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    CallSummary call,
  ) async {
    final strings = AppStrings.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.t('deleteConfirmTitle')),
        content: Text(strings.t('deleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await state.deleteCall(call);
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(strings.t('deleted'))),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.t('loadError'))),
      );
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.tokens.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: context.tokens.glassBorder),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
