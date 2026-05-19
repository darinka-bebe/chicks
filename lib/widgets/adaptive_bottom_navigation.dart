import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/platform/platform_info.dart';

/// Нижняя навигация: [CupertinoTabBar] на iOS, [NavigationBar] на Android.
class AdaptiveBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AdaptiveNavItem> items;

  const AdaptiveBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isCupertino) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: [
          for (final item in items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          ),
      ],
    );
  }
}

class AdaptiveNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AdaptiveNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
