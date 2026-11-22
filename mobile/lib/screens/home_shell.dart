import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_icon.dart';
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
                  icon: SoftIcon(AppIcon.home, size: 24, color: tokens.muted, solid: true),
                  selectedIcon: SoftIcon(AppIcon.home, size: 24, color: AppPalette.brand, solid: true),
                  label: strings.t('tabCalls'),
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: state.urgentCount,
                    isLabelVisible: state.urgentCount > 0,
                    backgroundColor: tokens.urgent,
                    child: SoftIcon(AppIcon.urgent, size: 24, color: tokens.muted, solid: true),
                  ),
                  selectedIcon: Badge.count(
                    count: state.urgentCount,
                    isLabelVisible: state.urgentCount > 0,
                    backgroundColor: tokens.urgent,
                    child: SoftIcon(AppIcon.urgent, size: 24, color: AppPalette.brand, solid: true),
                  ),
                  label: strings.t('tabUrgent'),
                ),
                NavigationDestination(
                  icon: _CallTabIcon(active: _index == 2),
                  label: strings.t('tabCall'),
                ),
                NavigationDestination(
                  icon: SoftIcon(AppIcon.calendar, size: 24, color: tokens.muted, solid: true),
                  selectedIcon: SoftIcon(AppIcon.calendar, size: 24, color: AppPalette.brand, solid: true),
                  label: strings.t('tabAppointments'),
                ),
                NavigationDestination(
                  icon: SoftIcon(AppIcon.settings, size: 24, color: tokens.muted, solid: true),
                  selectedIcon: SoftIcon(AppIcon.settings, size: 24, color: AppPalette.brand, solid: true),
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
    return SizedBox(
      width: 52,
      height: 40,
      child: Center(
        child: Transform.rotate(
          angle: 0.785398, // 45 derece: kare baklava sekline doner
          child: AnimatedContainer(
            duration: AppTheme.fast,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: tokens.brandGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.brand
                      .withValues(alpha: active ? 0.48 : 0.26),
                  blurRadius: active ? 18 : 11,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -0.785398,
              child: const Center(
                child: SoftIcon(AppIcon.phone,
                    size: 19, color: Colors.white, solid: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
