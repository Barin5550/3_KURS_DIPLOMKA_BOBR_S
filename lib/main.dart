// Файл main.dart — точка входа приложения «Маршрут».
// Слой: корень приложения (над слоями core / domain / data / presentation).
// Здесь готовятся локальная база данных и настройки, после чего запускается
// корневой виджет MarshrutApp из app.dart. Этот файл вызывает сам Flutter.
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'presentation/providers/providers.dart';

/// Точка входа. Создаёт базу данных и настройки, затем запускает приложение.
///
/// Облачные сервисы и ключи не нужны: все данные хранятся на устройстве.
Future<void> main() async {
  // Инициализируем связку Flutter с платформой заранее: без этого нельзя
  // обращаться к плагинам (настройки, файловая система) до runApp.
  WidgetsFlutterBinding.ensureInitialized();
  // Загружаем русские названия месяцев и дней недели для форматирования дат
  // (пакет intl), иначе DateFormat с локалью 'ru' выдаст ошибку.
  await initializeDateFormatting('ru');

  // Открываем хранилище простых настроек «ключ — значение»
  // (SharedPreferences): там лежат тема и сохранённая сессия входа.
  final prefs = await SharedPreferences.getInstance();
  // Создаём локальную базу данных SQLite через библиотеку Drift
  // (Drift — обёртка над SQLite с типобезопасными запросами).
  final database = AppDatabase(
    // driftDatabase сам выбирает способ открытия БД под платформу.
    driftDatabase(
      // Имя файла базы данных.
      name: 'marshrut',
      // Служебная папка приложения (в Windows — %APPDATA%), а не «Документы».
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      // Для веб-версии: SQLite, собранный в WebAssembly (sqlite3.wasm),
      // и фоновый воркер Drift (drift_worker.js); пути указаны
      // относительно адреса, с которого открыт сайт.
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  // Запускаем интерфейс приложения.
  runApp(
    // ProviderScope — контейнер Riverpod (библиотека управления
    // состоянием): в нём живут все провайдеры приложения.
    ProviderScope(
      // Подставляем готовые объекты БД и настроек вместо провайдеров-
      // заглушек: так весь остальной код получает их через ref.watch.
      overrides: [
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      // Корневой виджет приложения (тема, роутер, локализация).
      child: const MarshrutApp(),
    ),
  );
}
