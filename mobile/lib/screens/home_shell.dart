import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'appointments_screen.dart';
import 'call_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';
import 'urgent_screen.dart';

/// Uygulamanin kabugu: alt gezinme ve sayfalar.
///
/// Alt cubuk duz beyazdir (bulanik cam degil): acik temada cam efekti
/// okunabilirligi dusuruyordu. Secili sekme hem renk hem de dolu ikonla
/// belirtilir, boylece ayrim yalnizca renge dayanmaz.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goTo(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final pages = <Widget>[
      CallsScreen(
        onOpenSettings: () => _goTo(4),
        onStartCall: () => _goTo(2),
        onOpenUrgent: () => _goTo(1),
        onOpenAppointments: () => _goTo(3),
      ),
      UrgentScreen(onOpenSettings: () => _goTo(4)),
      CallScreen(onOpenSettings: () => _goTo(4)),
      AppointmentsScreen(onOpenSettings: () => _goTo(4)),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: tokens.isDark ? AppPalette.darkSurface : const Color(0xFFF7F7F8),
      body: AnimatedSwitcher(
        duration: AppTheme.normal,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.012),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
      ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: _goTo,
        urgentCount: state.urgentCount,
        labels: [
          strings.t('tabCalls'),
          strings.t('tabUrgent'),
          strings.t('tabCall'),
          strings.t('tabAppointments'),
          strings.t('tabSettings'),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.onChanged,
    required this.urgentCount,
    required this.labels,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int urgentCount;
  final List<String> labels;

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.bolt_outlined,
    Icons.phone_in_talk_outlined,
    Icons.calendar_today_outlined,
    Icons.tune_outlined,
  ];

  static const _activeIcons = <IconData>[
    Icons.home_rounded,
    Icons.bolt_rounded,
    Icons.phone_in_talk_rounded,
    Icons.calendar_month_rounded,
    Icons.tune_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.isDark ? AppPalette.darkCard : AppPalette.surface,
        border: Border(top: BorderSide(color: tokens.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _Tab(
                    label: labels[i],
                    icon: index == i ? _activeIcons[i] : _icons[i],
                    selected: index == i,
                    badge: i == 1 ? urgentCount : 0,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = selected ? AppPalette.orange : tokens.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        // Dokunma alani tum sutunu kaplar: 44x44 kuralinin ustunde kalir.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge.count(
              count: badge,
              isLabelVisible: badge > 0,
              backgroundColor: tokens.urgent,
              textColor: Colors.white,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
