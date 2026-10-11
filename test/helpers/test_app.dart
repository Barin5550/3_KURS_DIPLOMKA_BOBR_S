import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/data/datasources/catalog_repository_impl.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/services/reminder_service_impl.dart';
import 'package:marshrut/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Фиксированная «сегодняшняя» дата для тестов: понедельник, 12.10.2026.
final testToday = DateTime(2026, 10, 12, 10);

/// Каталог читается из файлов проекта, а не из rootBundle.
CatalogRepositoryImpl fileCatalog() =>
    CatalogRepositoryImpl((path) => File(path).readAsString());

/// База данных SQLite в оперативной памяти.
AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// Контейнер зависимостей для тестов: база в памяти, пустые настройки,
/// уведомления-заглушки, фиксированное время.
Future<List<Override>> testOverrides({
  AppDatabase? db,
  Map<String, Object> prefs = const {},
  DateTime Function()? clock,
}) async {
  await initializeDateFormatting('ru');
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  // Каталог читается заранее (реальный ввод-вывод), дальше берётся из кэша.
  final catalog = fileCatalog();
  await catalog.loadDirections();
  return [
    databaseProvider.overrideWithValue(db ?? memoryDatabase()),
    sharedPreferencesProvider.overrideWithValue(sp),
    reminderServiceProvider.overrideWithValue(NoopReminderService()),
    catalogRepositoryProvider.overrideWithValue(catalog),
    clockProvider.overrideWithValue(clock ?? () => testToday),
  ];
}

/// Запускает всё приложение с тестовыми зависимостями.
Future<void> pumpTestApp(
  WidgetTester tester, {
  AppDatabase? db,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final overrides = await tester.runAsync(
    () => testOverrides(db: db, prefs: prefs),
  );
  await tester.pumpWidget(
    ProviderScope(overrides: overrides!, child: const MarshrutApp()),
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
