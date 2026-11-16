import 'dart:ui' show ImageFilter;

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
      extendBody: true,
      backgroundColor: tokens.mesh.first,
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
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.glassStrong,
              border: Border(top: BorderSide(color: tokens.glassBorder)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
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
        ),
      ),
    );
  }
}

/// Arama sekmesi, degradeli yuvarlak bir dugme olarak one cikar.
class _CallTabIcon extends StatelessWidget {
  const _CallTabIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: AppTheme.fast,
      width: 46,
      height: 32,
      decoration: BoxDecoration(
        gradient: tokens.brandGradient,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppPalette.brand.withValues(alpha: active ? 0.45 : 0.22),
            blurRadius: active ? 18 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.call_rounded, size: 18, color: Colors.white),
    );
  }
}
