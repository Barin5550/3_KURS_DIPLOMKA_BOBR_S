import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common.dart';

/// Каркас с навигацией из пяти вкладок.
///
/// Каждая вкладка — отдельная ветка StatefulShellRoute, поэтому при
/// переключении вкладок сохраняются их состояние и позиция прокрутки.
///
/// Адаптивность: на телефоне в вертикальной ориентации вкладки внизу
/// (NavigationBar), на широком экране — слева (NavigationRail), чтобы не
/// отнимать высоту у содержимого.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Главная',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'План',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Темы',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Статистика',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Профиль',
    ),
  ];

  void _select(int index) => navigationShell.goBranch(
    index,
    // Повторное нажатие на активную вкладку возвращает к её началу.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: AppLogo(size: 40),
                ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: _select,
      ),
    );
  }
}
