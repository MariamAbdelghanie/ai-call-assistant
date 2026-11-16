import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'appointments_screen.dart';
import 'call_screen.dart';
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

  void _goTo(int value) => setState(() => _index = value);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final strings = AppStrings.of(context);
    final tokens = context.tokens;

    final pages = <Widget>[
      CallsScreen(onOpenSettings: () => _goTo(4), onStartCall: () => _goTo(2)),
      UrgentScreen(onOpenSettings: () => _goTo(4)),
      CallScreen(onOpenSettings: () => _goTo(4)),
      AppointmentsScreen(onOpenSettings: () => _goTo(4)),
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
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
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
                backgroundColor: tokens.urgent,
                child: const Icon(Icons.bolt_outlined),
              ),
              selectedIcon: Badge.count(
                count: state.urgentCount,
                isLabelVisible: state.urgentCount > 0,
                backgroundColor: tokens.urgent,
                child: const Icon(Icons.bolt_rounded),
              ),
              label: strings.t('tabUrgent'),
            ),
            NavigationDestination(
              icon: _CallTabIcon(active: _index == 2),
              label: strings.t('tabCall'),
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
      ),
    );
  }
}

/// Arama sekmesi, gradyanli yuvarlak bir dugme olarak one cikar.
class _CallTabIcon extends StatelessWidget {
  const _CallTabIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: AppTheme.fast,
      width: 44,
      height: 32,
      decoration: BoxDecoration(
        gradient: tokens.brandGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: active
            ? [BoxShadow(color: tokens.glow, blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: const Icon(Icons.call_rounded, size: 18, color: Colors.white),
    );
  }
}
