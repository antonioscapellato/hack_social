import 'package:flutter/material.dart';

/// Custom navigation bar wrapper that matches LuckyUI design principles
class LuckyNavBarWrapper extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LuckyNavBarItemWrapper> items;

  const LuckyNavBarWrapper({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon, size: 28),
          selectedIcon: Icon(item.selectedIcon ?? item.icon, size: 28),
          label: item.label ?? '',
        );
      }).toList(),
    );
  }
}

class LuckyNavBarItemWrapper {
  final IconData icon;
  final IconData? selectedIcon;
  final String? label;

  LuckyNavBarItemWrapper({
    required this.icon,
    this.selectedIcon,
    this.label,
  });
}

