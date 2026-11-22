import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/call_summary.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
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
class UrgentScreen extends StatelessWidget {
  const UrgentScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final items = state.urgentCalls;
    final waiting = items.where((c) => !c.calledBack).length;

    return GlassScaffold(
      title: strings.t('urgentTitle'),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
          children: [
            if (state.isDemo || state.isOffline)
              DemoBanner(
                onOpenSettings: onOpenSettings,
                offline: state.isOffline,
              ),

            _UrgentHeader(total: items.length, waiting: waiting),
            const SizedBox(height: 18),

            if (items.isEmpty)
              EmptyState(
                icon: AppIcon.check,
                title: strings.t('emptyUrgent'),
                message: strings.t('emptyUrgentHint'),
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
                          builder: (_) =>
                              CallDetailScreen(callId: call.callId),
                        ),
                      ),
                      onToggle: () => state.toggleCalledBack(call),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Kirmizi ust blok: kac acil cagri var, kaci hala bekliyor.
class _UrgentHeader extends StatelessWidget {
  const _UrgentHeader({required this.total, required this.waiting});

  final int total;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final calm = total == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: calm
              ? const [Color(0xFF4ECE9A), Color(0xFF2FA878)]
              : const [Color(0xFFF4707A), Color(0xFFE03B48)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (calm ? AppPalette.success : AppPalette.urgent)
                .withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SoftIcon(
                calm ? AppIcon.check : AppIcon.urgent,
                size: 24,
                color: Colors.white,
                solid: true,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calm
                      ? strings.t('urgentCalm')
                      : '$waiting ${strings.t('urgentWaiting')}',
                  style: context.text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  calm
                      ? strings.t('urgentCalmHint')
                      : '${strings.t('statTotal')}: $total',
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '#$rank',
                            style: context.text.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            call.callerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          Formatters.friendly(call.timestamp, strings),
                          style: context.text.labelSmall
                              ?.copyWith(color: tokens.muted),
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
                          label: strings
                              .t(done ? 'calledBack' : 'markCalledBack'),
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
