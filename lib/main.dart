// Файл main.dart — точка входа приложения «Маршрут».
// Слой: корень приложения (над слоями core / domain / data / presentation).
// Здесь готовятся настройки устройства, после чего запускается корневой
// виджет MarshrutApp из app.dart. Этот файл вызывает сам Flutter.
// Своей базы данных у приложения нет: все данные оно получает и сохраняет
// через сервер API (bin/marshrut_server.dart).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'presentation/providers/providers.dart';

/// Точка входа. Открывает настройки устройства и запускает приложение.
Future<void> main() async {
  // Инициализируем связку Flutter с платформой заранее: без этого нельзя
  // обращаться к плагинам (настройки, уведомления) до runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Загружаем русские названия месяцев и дней недели для форматирования дат
  // (пакет intl), иначе DateFormat с локалью 'ru' выдаст ошибку.
  await initializeDateFormatting('ru');

  // Открываем хранилище простых настроек «ключ — значение»
  // (SharedPreferences): там лежат адрес сервера, сохранённая сессия входа
  // и тема оформления.
  final prefs = await SharedPreferences.getInstance();

  // Запускаем интерфейс приложения.
  runApp(
    // ProviderScope — контейнер Riverpod (библиотека управления
    // состоянием): в нём живут все провайдеры приложения.
    ProviderScope(
      // Подставляем готовые настройки вместо провайдера-заглушки: так весь
      // остальной код получает их через ref.watch.
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      // Корневой виджет приложения (тема, роутер, локализация).
      child: const MarshrutApp(),
    ),
  );
}
