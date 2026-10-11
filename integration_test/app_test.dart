import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/services/reminder_service_impl.dart';
import 'package:marshrut/presentation/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Интеграционный тест: настоящее приложение на устройстве или эмуляторе.
///
/// Запуск: `flutter test integration_test` (нужен подключённый девайс,
/// эмулятор или настольная платформа). База — SQLite в памяти, чтобы не
/// трогать данные пользователя.
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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
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

    // Вход.
    await waitFor(tester, find.text('demo@mail.ru'));
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

    // Убираем дерево виджетов, чтобы закрыть подписки на базу.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    await db.close();
  });
}
