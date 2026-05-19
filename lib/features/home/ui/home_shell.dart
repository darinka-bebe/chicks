import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/platform/platform_info.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/adaptive_bottom_navigation.dart';

/// Оболочка (Shell) для домашних вкладок.
///
/// Используется с [ShellRoute] из GoRouter.
/// [ShellRoute] оборачивает дочерние роуты в общий layout —
/// в нашем случае это [Scaffold] с [BottomNavigationBar].
///
/// [child] — это текущий экран вкладки (MainTab или ProfileTab),
/// который GoRouter подставляет автоматически.
class HomeShell extends StatelessWidget {
  /// Текущий дочерний виджет (вкладка).
  final Widget child;

  const HomeShell({super.key, required this.child});

  /// Определяем текущий индекс вкладки по URL.
  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home/profile')) {
      return AppConstants.profileTabIndex;
    }
    return AppConstants.mainTabIndex;
  }

  /// Обработчик переключения вкладок.
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
    // Получаем объект локализации для доступа к переведённым строкам.
    // Теперь строки доступны как геттеры: loc.tabMain, loc.tabProfile и т.д.
    final loc = AppLocalizations.of(context);
    final int selectedIndex = _currentIndex(context);

    final navItems = [
      AdaptiveNavItem(
        icon: PlatformInfo.isCupertino
            ? CupertinoIcons.house
            : Icons.home_outlined,
        activeIcon: PlatformInfo.isCupertino
            ? CupertinoIcons.house_fill
            : Icons.home,
        label: loc.tabMain,
      ),
      AdaptiveNavItem(
        icon: PlatformInfo.isCupertino
            ? CupertinoIcons.person
            : Icons.person_outline,
        activeIcon: PlatformInfo.isCupertino
            ? CupertinoIcons.person_fill
            : Icons.person,
        label: loc.tabProfile,
      ),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: true,
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: AdaptiveBottomNavigation(
        currentIndex: selectedIndex,
        onTap: (index) => _onTabTapped(context, index),
        items: navItems,
      ),
    );
  }
}
