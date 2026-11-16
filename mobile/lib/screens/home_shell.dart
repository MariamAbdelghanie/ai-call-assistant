import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'appointments_screen.dart';
import 'calls_screen.dart';
import 'settings_screen.dart';
import 'urgent_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _goToSettings() => setState(() => _index = 3);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);

    final pages = <Widget>[
      CallsScreen(onOpenSettings: _goToSettings),
      UrgentScreen(onOpenSettings: _goToSettings),
      AppointmentsScreen(onOpenSettings: _goToSettings),
      const SettingsScreen(),
    ];

    return Scaffold(
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
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum_rounded),
            label: strings.t('tabCalls'),
          ),
          NavigationDestination(
            icon: Badge.count(
              count: state.urgentCount,
              isLabelVisible: state.urgentCount > 0,
              backgroundColor: context.status.urgent,
              child: const Icon(Icons.priority_high_rounded),
            ),
            selectedIcon: Badge.count(
              count: state.urgentCount,
              isLabelVisible: state.urgentCount > 0,
              backgroundColor: context.status.urgent,
              child: const Icon(Icons.notifications_active_rounded),
            ),
            label: strings.t('tabUrgent'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event_rounded),
            label: strings.t('tabAppointments'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: strings.t('tabSettings'),
          ),
        ],
      ),
    );
  }
}
