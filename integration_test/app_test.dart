import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/core/utils/password_hasher.dart';
import 'package:marshrut/data/datasources/catalog_repository_impl.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/services/reminder_service_impl.dart';
import 'package:marshrut/presentation/providers/providers.dart';
import 'package:marshrut/server/api_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Интеграционный тест: настоящее приложение на устройстве или эмуляторе.
///
/// Запуск: `flutter test integration_test` (нужен подключённый девайс,
/// эмулятор или настольная платформа). Прямо в тесте запускается настоящий
/// сервер API на адресе 127.0.0.1 со своей базой SQLite в памяти, и
/// приложение ходит к нему по HTTP — так же, как к серверу на ноутбуке.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Ждёт появления виджета: на реальном устройстве база и анимации
  /// работают в реальном времени.
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        throw TestFailure('Не дождались: $finder');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await waitFor(tester, finder);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tap(tester, finder);
  }

  testWidgets('Splash → Регистрация → Вход → План → Профиль → Выход', (
    tester,
  ) async {
    await initializeDateFormatting('ru');

    // Сервер API: база в памяти, каталог из ресурсов приложения, свободный
    // порт на 127.0.0.1 (порт 0 — «выбери любой свободный»).
    final db = AppDatabase(NativeDatabase.memory());
    final catalog = [
      for (final path in CatalogRepositoryImpl.files)
        jsonDecode(await rootBundle.loadString(path)),
    ];
    final api = ApiServer(
      db: db,
      catalog: catalog,
      // Меньше итераций PBKDF2, чтобы тест не ждал хэширование.
      hasher: PasswordHasher(iterations: 1000),
    );
    final server = await shelf_io.serve(
      api.handler,
      InternetAddress.loopbackIPv4,
      0,
    );

    // Приложение сразу знает адрес тестового сервера.
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://127.0.0.1:${server.port}',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(NoopReminderService()),
          // Фиксированный понедельник: в учебный день на главной есть занятия.
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 12, 10)),
        ],
        child: const MarshrutApp(),
      ),
    );

    // Splash сам переходит на вход.
    expect(find.text('Маршрут'), findsOneWidget);
    await waitFor(tester, find.text('С возвращением!'));

    // Регистрация.
    await tap(tester, find.byKey(const Key('go_register')));
    await waitFor(tester, find.byKey(const Key('reg_name')));
    await tester.enterText(find.byKey(const Key('reg_name')), 'Демо');
    await tester.enterText(find.byKey(const Key('reg_email')), 'demo@mail.ru');
    await tester.enterText(find.byKey(const Key('reg_password')), 'demo2026');
    await tester.enterText(find.byKey(const Key('reg_confirm')), 'demo2026');
    await tap(tester, find.byKey(const Key('reg_submit')));

    // Вход. Регистрация идёт через сервер, поэтому ждём именно экран
    // входа, а не текст email (он есть и в форме регистрации).
    await waitFor(tester, find.byKey(const Key('login_password')));
    expect(find.text('demo@mail.ru'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login_password')), 'demo2026');
    await tap(tester, find.byKey(const Key('login_submit')));
    await waitFor(tester, find.byKey(const Key('home_empty')));

    // Создание плана по направлению «Python» без теста.
    await tap(tester, find.text('Создать план'));
    await tap(tester, find.byKey(const Key('direction_python')));
    await tap(tester, find.byKey(const Key('test_skip')));
    await tap(tester, find.byKey(const Key('schedule_generate')));
    await waitFor(tester, find.text('Ваш план готов'));
    await scrollAndTap(tester, find.byKey(const Key('preview_save')));
    await waitFor(tester, find.byType(Checkbox));

    // Вкладки и профиль.
    await tap(tester, find.text('План'));
    await waitFor(tester, find.byKey(const Key('plan_search')));
    await tap(tester, find.text('Профиль').last);
    await waitFor(tester, find.byKey(const Key('profile_name')));

    // Выход с подтверждением.
    await scrollAndTap(tester, find.byKey(const Key('logout_button')));
    await tap(tester, find.text('Выйти').last);
    await waitFor(tester, find.text('С возвращением!'));

    // Убираем дерево виджетов, чтобы закрыть подписки, и останавливаем
    // сервер.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    await server.close(force: true);
    await db.close();
  });
}
