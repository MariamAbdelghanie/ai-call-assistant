import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/caller_avatar.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/soft_icon.dart';
import 'call_detail_screen.dart';

/// Acil cagrilar ekrani.
///
/// Burada amac goz gezdirmek degil, hemen harekete gecmek. Bu yuzden liste
/// satirlari yerine solunda kalin kirmizi bir serit olan genis kartlar
/// kullanilir; her kartta mesaj tam olarak okunur ve "arandi" dugmesi
/// dogrudan karta yerlesir.
class UrgentScreen extends StatefulWidget {
  const UrgentScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<UrgentScreen> createState() => _UrgentScreenState();
}

class _UrgentScreenState extends State<UrgentScreen> {
  /// 0 = tumu, 1 = bekleyen, 2 = tamamlandi.
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final all = state.urgentCalls;
    final waiting = all.where((c) => !c.calledBack).length;
    final items = switch (_tab) {
      1 => all.where((c) => !c.calledBack).toList(),
      2 => all.where((c) => c.calledBack).toList(),
      _ => all,
    };

    return PageScaffold(
      title: strings.t('urgentTitle'),
      subtitle: all.isEmpty
          ? strings.t('urgentCalm')
          : '$waiting ${strings.t('urgentWaiting')}',
      onRefresh: state.refresh,
      children: [
        if (state.isDemo || state.isOffline) ...[
          DemoBanner(
            onOpenSettings: widget.onOpenSettings,
            offline: state.isOffline,
          ),
          const SizedBox(height: 14),
        ],

        // Durum sekmeleri: liste bu secime gore filtreleniyor.
        _Segmented(
          labels: [
            strings.t('filterAll'),
            strings.t('urgentTabWaiting'),
            strings.t('urgentTabDone'),
          ],
          selected: _tab,
          onChanged: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),

        if (items.isEmpty)
          EmptyState(
            icon: _tab == 0 ? AppIcon.check : AppIcon.inbox,
            title: _tab == 0
                ? strings.t('emptyUrgent')
                : strings.t('emptyFiltered'),
            message: _tab == 0
                ? strings.t('emptyUrgentHint')
                : strings.t('emptyFilteredHint'),
          )
        else
          for (final (index, call) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AnimatedEntrance(
                index: index,
                child: _UrgentCard(
                  call: call,
                  rank: index + 1,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CallDetailScreen(callId: call.callId),
                    ),
                  ),
                  onToggle: () => state.toggleCalledBack(call),
                ),
              ),
            ),
      ],
    );
  }
}

/// Sade durum sekmeleri: secili olan turuncu dolu, digerleri cerceveli.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Row(
      children: [
        for (final (index, label) in labels.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: index == selected
                      ? AppPalette.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: index == selected
                        ? AppPalette.orange
                        : tokens.glassBorder,
                  ),
                ),
                child: Text(
                  label,
                  style: context.text.titleSmall?.copyWith(
                    color: index == selected ? Colors.white : tokens.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tek bir acil cagri karti.
class _UrgentCard extends StatelessWidget {
  const _UrgentCard({
    required this.call,
    required this.rank,
    required this.onTap,
    required this.onToggle,
  });

  final CallSummary call;
  final int rank;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tokens = context.tokens;
    final done = call.calledBack;
    final accent = done ? tokens.success : tokens.urgent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol serit: oncelik hissini veren tek gorsel oge.
            Container(width: 6, color: accent),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                radius: 0,
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CallerAvatar(name: call.callerName, size: 42),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                call.callerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '#$rank · '
                                '${Formatters.friendly(call.timestamp, strings)}',
                                style: context.text.labelSmall
                                    ?.copyWith(color: tokens.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Durum rozeti: karta bakar bakmaz bu cagrinin
                        // kapanip kapanmadigi gorulsun.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            strings
                                .t(done ? 'urgentTabDone' : 'urgentTabWaiting'),
                            style: context.text.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      call.summary.trim().isEmpty
                          ? call.callerPurpose
                          : call.summary,
                      style: context.text.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (call.callerNumber.trim().isNotEmpty) ...[
                          SoftIcon(AppIcon.phone,
                              size: 13, color: tokens.muted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              call.callerNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall
                                  ?.copyWith(color: tokens.muted),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const SizedBox(width: 8),
                        _ActionChip(
                          done: done,
                          label:
                              strings.t(done ? 'calledBack' : 'markCalledBack'),
                          onTap: onToggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.done,
    required this.label,
    required this.onTap,
  });

  final bool done;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = done ? tokens.success : AppPalette.brand;

    return Material(
      color: done ? color.withValues(alpha: 0.12) : color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SoftIcon(
                done ? AppIcon.check : AppIcon.phoneBack,
                size: 14,
                color: done ? color : Colors.white,
                solid: true,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: done ? color : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
