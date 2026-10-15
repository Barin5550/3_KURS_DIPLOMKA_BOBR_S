// Каркас главной части приложения с панелью из пяти вкладок
// (Главная, План, Темы, Статистика, Профиль).
// Слой: presentation (интерфейс). Создаётся роутером
// (core/router/app_router.dart) внутри StatefulShellRoute; содержимое
// вкладок — отдельные экраны, которые роутер подставляет в navigationShell.
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
  /// Создаёт каркас; [navigationShell] передаёт роутер go_router.
  const MainShell({super.key, required this.navigationShell});

  /// Объект go_router, который хранит ветки вкладок: знает текущую
  /// вкладку, умеет переключать их и сам является виджетом с содержимым
  /// активной вкладки.
  final StatefulNavigationShell navigationShell;

  /// Описание пяти вкладок: обычная иконка, иконка выбранной вкладки и
  /// подпись. Порядок совпадает с порядком веток в роутере.
  static const destinations = [
    // Вкладка «Главная» — экран /home.
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Главная',
    ),
    // Вкладка «План» — экран /plan.
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'План',
    ),
    // Вкладка «Темы» — экран /topics.
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Темы',
    ),
    // Вкладка «Статистика» — экран /stats.
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Статистика',
    ),
    // Вкладка «Профиль» — экран /profile.
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Профиль',
    ),
  ];

  /// Переключает на вкладку с номером [index] (вызывается при нажатии на
  /// вкладку в нижней или боковой панели).
  void _select(int index) => navigationShell.goBranch(
    index,
    // Повторное нажатие на активную вкладку возвращает к её началу.
    initialLocation: index == navigationShell.currentIndex,
  );

  /// Строит каркас: выбирает боковую или нижнюю панель в зависимости от
  /// ширины экрана.
  @override
  Widget build(BuildContext context) {
    // Широкий экран — ширина не меньше порога из common.dart (840).
    final wide = MediaQuery.sizeOf(context).width >= kWideLayoutBreakpoint;
    // Вариант для широкого экрана: панель вкладок слева.
    if (wide) {
      return Scaffold(
        // Строка: боковая панель | разделитель | содержимое вкладки.
        body: Row(
          children: [
            // SafeArea не даёт панели залезть под вырез и системные
            // элементы экрана (кроме правого края — там содержимое).
            SafeArea(
              right: false,
              // Боковая панель навигации Material 3.
              child: NavigationRail(
                // Подсвечивается текущая вкладка.
                selectedIndex: navigationShell.currentIndex,
                // При нажатии переключаем вкладку через _select.
                onDestinationSelected: _select,
                // Подписи показываются у всех вкладок, а не только у
                // выбранной.
                labelType: NavigationRailLabelType.all,
                // Логотип приложения над списком вкладок.
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: AppLogo(size: 40),
                ),
                // Те же пять вкладок, переделанные в формат боковой
                // панели (подпись здесь должна быть виджетом Text).
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
            // Тонкая вертикальная линия между панелью и содержимым.
            const VerticalDivider(width: 1),
            // Содержимое активной вкладки занимает всё остальное место.
            Expanded(child: navigationShell),
          ],
        ),
      );
    }
    // Вариант для телефона: содержимое вкладки и панель вкладок внизу.
    return Scaffold(
      body: navigationShell,
      // Подписи вкладок не увеличиваются вместе с системным шрифтом:
      // иначе «Статистика» не помещается и переносится по буквам.
      bottomNavigationBar: MediaQuery.withNoTextScaling(
        // Нижняя панель навигации Material 3.
        child: NavigationBar(
          // Подсвечивается текущая вкладка.
          selectedIndex: navigationShell.currentIndex,
          destinations: destinations,
          // При нажатии переключаем вкладку через _select.
          onDestinationSelected: _select,
        ),
      ),
    );
  }
}
