import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Оболочка (Shell) для домашних вкладок с анимированным BottomNavigationBar.
///
/// [child] — текущий экран вкладки (MainTab или ProfileTab),
/// который GoRouter подставляет автоматически.
///
/// Улучшения:
/// - NavigationBar (Material 3) вместо BottomNavigationBar.
/// - Индикатор активной вкладки с анимацией.
/// - Мгновенное переключение вкладок без анимации (лучший UX).
class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home/profile')) {
      return AppConstants.profileTabIndex;
    }
    return AppConstants.mainTabIndex;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case AppConstants.mainTabIndex:
        context.go('/home/main');
        break;
      case AppConstants.profileTabIndex:
        context.go('/home/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final int selectedIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onTabTapped(context, index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFD6E8),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        elevation: 8,
        height: 64,
        animationDuration: const Duration(milliseconds: 350),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(
              Icons.home,
              color: Color(0xFFFF4FA0),
            ),
            label: loc.tabMain,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(
              Icons.person,
              color: Color(0xFFFF4FA0),
            ),
            label: loc.tabProfile,
          ),
        ],
        ),
      ),
    );
  }
}
