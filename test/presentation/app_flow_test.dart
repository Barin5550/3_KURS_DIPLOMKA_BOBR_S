import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/data/db/app_database.dart';

import '../helpers/test_app.dart';

/// Сквозной сценарий демонстрации 1 семестра:
/// Splash → Регистрация → Вход → Главная → Навигация → Профиль →
/// Основной раздел (создание плана) → Выход.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      // Элемент ещё не построен ленивым списком — прокручиваем к нему.
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    // Без кадра после прокрутки tap() берёт старые координаты.
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('полный сценарий без ошибок', (tester) async {
    await pumpTestApp(tester, db: db);

    // Splash: логотип и название.
    expect(find.text('Маршрут'), findsOneWidget);
    expect(find.text('Персональный план обучения'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);

    // Сессии нет → экран входа.
    expect(find.text('С возвращением!'), findsOneWidget);

    // Переход к регистрации.
    await tapAndSettle(tester, find.byKey(const Key('go_register')));
    expect(find.text('Создать аккаунт'), findsOneWidget);

    // Пустая форма → сообщения об ошибках.
    await tapAndSettle(tester, find.byKey(const Key('reg_submit')));
    expect(find.text('Введите имя'), findsOneWidget);
    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    // Корректные данные → регистрация → экран входа с email.
    await tester.enterText(find.byKey(const Key('reg_name')), 'Алия');
    await tester.enterText(find.byKey(const Key('reg_email')), 'aliya@mail.ru');
    await tester.enterText(
      find.byKey(const Key('reg_password')),
      'flutter2026',
    );
    await tester.enterText(find.byKey(const Key('reg_confirm')), 'flutter2026');
    await tapAndSettle(tester, find.byKey(const Key('reg_submit')));
    expect(find.text('С возвращением!'), findsOneWidget);
    expect(find.text('aliya@mail.ru'), findsOneWidget);

    // Неверный пароль → сообщение об ошибке.
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong123');
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.text('Неверный email или пароль'), findsOneWidget);

    // Верный пароль → главная (плана ещё нет).
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'flutter2026',
    );
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.text('Привет, Алия!'), findsOneWidget);
    expect(find.byKey(const Key('home_empty')), findsOneWidget);

    // Основной раздел: создание плана.
    await tapAndSettle(tester, find.text('Создать план'));
    await tapAndSettle(tester, find.byKey(const Key('direction_flutter')));
    expect(find.textContaining('Вопрос 1 из'), findsOneWidget);

    // Отвечаем на первый вопрос верно (final vs const — вариант 1).
    await tapAndSettle(tester, find.byKey(const Key('option_1')));
    await tapAndSettle(tester, find.byKey(const Key('test_next')));
    expect(find.textContaining('Вопрос 2 из'), findsOneWidget);

    // Остальное пропускаем: «Я новичок».
    await tapAndSettle(tester, find.byKey(const Key('test_skip')));
    expect(find.text('Сколько часов в неделю?'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('schedule_generate')));
    expect(find.text('Ваш план готов'), findsOneWidget);
    expect(find.text('Порядок тем'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('preview_save')));
    expect(find.text('Flutter-разработчик'), findsWidgets);
    expect(find.textContaining('Сегодня, 12 октября'), findsOneWidget);

    // Отмечаем первое занятие дня.
    final checkbox = find.byType(Checkbox).first;
    await tapAndSettle(tester, checkbox);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);

    // Навигация по вкладкам.
    await tapAndSettle(tester, find.text('План'));
    expect(find.byKey(const Key('plan_search')), findsOneWidget);
    await tapAndSettle(tester, find.text('Темы'));
    expect(find.byKey(const Key('topics_search')), findsOneWidget);
    await tapAndSettle(tester, find.text('Статистика'));
    expect(find.text('Часы по неделям'), findsOneWidget);
    await tapAndSettle(tester, find.text('Профиль').last);
    expect(find.byKey(const Key('profile_name')), findsOneWidget);
    expect(find.text('aliya@mail.ru'), findsOneWidget);

    // Выход.
    await tapAndSettle(tester, find.byKey(const Key('logout_button')));
    await tapAndSettle(tester, find.text('Выйти').last);
    expect(find.text('С возвращением!'), findsOneWidget);

    // Закрытые экраны недоступны без входа: redirect возвращает на вход.
    final context = tester.element(find.text('С возвращением!'));
    GoRouter.of(context).go('/profile');
    await settle(tester);
    expect(find.text('С возвращением!'), findsOneWidget);
    expect(find.byKey(const Key('profile_name')), findsNothing);

    // Повторный вход тем же пользователем: план сохранился.
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'aliya@mail.ru',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'flutter2026',
    );
    await tapAndSettle(tester, find.byKey(const Key('login_submit')));
    expect(find.text('Привет, Алия!'), findsOneWidget);
    expect(find.byKey(const Key('home_empty')), findsNothing);

    // Освобождаем таймеры drift перед завершением теста.
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
  });
}
