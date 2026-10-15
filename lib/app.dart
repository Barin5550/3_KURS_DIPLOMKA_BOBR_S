// Файл app.dart — корневой виджет приложения MarshrutApp.
// Слой: presentation (верхний уровень интерфейса).
// Собирает вместе тему (core/theme), роутер (core/router) и русскую
// локализацию. Создаётся в main.dart внутри ProviderScope.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';

/// Корневой виджет: тема, локализация и роутер.
///
/// Наследуется от ConsumerWidget (виджет Riverpod), чтобы читать провайдеры
/// через `ref` и перестраиваться при их изменении.
class MarshrutApp extends ConsumerWidget {
  /// Создаёт корневой виджет приложения.
  const MarshrutApp({super.key});

  /// Строит MaterialApp с роутером и выбранной пользователем темой.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем роутер go_router из провайдера (описан в app_router.dart).
    final router = ref.watch(routerProvider);
    // Переводим строковую настройку темы ('light' / 'dark' / иное) в
    // ThemeMode; всё, кроме light и dark, означает «как в системе».
    final themeMode = switch (ref.watch(themeModeProvider)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    // MaterialApp.router — приложение Material, навигацией в котором
    // управляет переданный роутер.
    return MaterialApp.router(
      // Название приложения (видно в списке задач ОС).
      title: 'Маршрут',
      // Убираем ленточку «DEBUG» в углу экрана.
      debugShowCheckedModeBanner: false,
      // Светлая и тёмная темы из app_theme.dart и текущий режим.
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Подключаем роутер: он решает, какой экран показать.
      routerConfig: router,
      // Интерфейс всегда на русском; английский указан как запасной.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      // Переводы стандартных виджетов Material (календарь, кнопки диалогов).
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
