import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/core/utils/password_hasher.dart';
import 'package:marshrut/data/datasources/catalog_repository_impl.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/auth_repository_impl.dart';
import 'package:marshrut/data/services/reminder_service_impl.dart';
import 'package:marshrut/domain/repositories/repositories.dart';
import 'package:marshrut/presentation/providers/providers.dart';
import 'package:marshrut/server/api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Фиксированная «сегодняшняя» дата для тестов: понедельник, 12.10.2026.
final testToday = DateTime(2026, 10, 12, 10);

/// Логические размеры экранов для проверки адаптивности.
const phoneSize = Size(392.7, 850.9);
const phoneLandscapeSize = Size(850.9, 392.7);
const desktopSize = Size(1280, 800);

/// Каталог читается из файлов проекта, а не из rootBundle.
CatalogRepositoryImpl fileCatalog() =>
    CatalogRepositoryImpl((path) => File(path).readAsString());

/// Каталог в виде JSON-объектов — так его отдаёт сервер API.
List<Object?> catalogJson() => [
  for (final path in CatalogRepositoryImpl.files)
    jsonDecode(File(path).readAsStringSync()),
];

/// Хэширование паролей с малым числом итераций: алгоритм тот же,
/// но тесты не тратят время на 100 000 повторений HMAC.
PasswordHasher fastHasher() => PasswordHasher(iterations: 1000);

/// Репозиторий пользователей для подготовки данных в тестах.
AuthRepositoryImpl testAuthRepository(AppDatabase db) =>
    AuthRepositoryImpl(db, hasher: fastHasher());

/// База данных SQLite в оперативной памяти.
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Сервер API поверх базы [db] — тот же код, что в настоящем сервере.
ApiServer testServer(AppDatabase db) =>
    ApiServer(db: db, catalog: catalogJson(), hasher: fastHasher());

/// Обработчик для MockClient: передаёт запрос серверу [server] прямо в
/// памяти, без сети — запрос пакета http превращается в запрос shelf и
/// обратно.
MockClientHandler inMemoryHandler(ApiServer server) => (request) async {
  final response = await server.handler(
    shelf.Request(
      request.method,
      request.url,
      headers: request.headers,
      body: request.bodyBytes,
    ),
  );
  final bytes = await response.read().expand((chunk) => chunk).toList();
  return http.Response.bytes(
    bytes,
    response.statusCode,
    headers: response.headers,
    request: request,
  );
};

/// HTTP-клиент, который работает с сервером [server] в памяти.
http.Client inMemoryClient(ApiServer server) =>
    MockClient(inMemoryHandler(server));

/// Контейнер зависимостей для тестов: сервер API с базой в памяти,
/// пустые настройки, уведомления-заглушки, фиксированное время.
///
/// Если в [prefs] есть `current_user_id`, а токена нет, тестовый сервер
/// сразу выдаёт этому пользователю токен — как будто он вошёл
/// с «Запомнить меня». [httpClient] заменяет связь с сервером (например,
/// клиентом, который всегда отвечает «нет сети»).
Future<List<Override>> testOverrides({
  AppDatabase? db,
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
  ReminderService? reminders,
  http.Client? httpClient,
}) async {
  await initializeDateFormatting('ru');
  final database = db ?? memoryDatabase();
  final server = testServer(database);
  final values = {...prefs};
  final userId = values['current_user_id'];
  if (userId is int && !values.containsKey('auth_token')) {
    final exists = await testAuthRepository(database).userById(userId);
    // Для несуществующего пользователя — заведомо неверный токен.
    values['auth_token'] = exists == null
        ? 'invalid-token'
        : await server.issueToken(userId);
  }
  SharedPreferences.setMockInitialValues(values);
  final sp = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    httpClientProvider.overrideWithValue(httpClient ?? inMemoryClient(server)),
    reminderServiceProvider.overrideWithValue(
      reminders ?? NoopReminderService(),
    ),
    clockProvider.overrideWithValue(clock ?? () => testToday),
  ];
}

/// Запускает всё приложение с тестовыми зависимостями.
Future<void> pumpTestApp(
  WidgetTester tester, {
  AppDatabase? db,
  Map<String, Object> prefs = const {},
  ReminderService? reminders,
  http.Client? httpClient,
  Size size = phoneSize,
}) async {
  tester.view.devicePixelRatio = 2.75;
  tester.view.physicalSize = size * 2.75;
  addTearDown(tester.view.reset);
  final base = await tester.runAsync(
    () => testOverrides(
      db: db,
      prefs: prefs,
      reminders: reminders,
      httpClient: httpClient,
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: base!,
      retry: noAutoRetry,
      child: const MarshrutApp(),
    ),
  );
}

/// Оборачивает один экран в MaterialApp с ProviderScope (для виджет-тестов).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  final base = await tester.runAsync(testOverrides);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...base!, ...overrides],
      retry: noAutoRetry,
      child: MaterialApp(home: screen),
    ),
  );
}

/// pump с ожиданием реальных асинхронных операций (база данных, файлы).
Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}
