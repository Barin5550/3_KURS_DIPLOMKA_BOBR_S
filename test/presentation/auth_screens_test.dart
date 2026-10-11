import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/data/db/app_database.dart';

import '../helpers/test_app.dart';

/// Виджет-тесты экранов входа и регистрации.
void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  Future<int> seedUser() async {
    final user = await testAuthRepository(db)
        .register(name: 'Ира', email: 'ira@mail.ru', password: 'secret123');
    return user.id;
  }

  /// Запускает приложение и ждёт окончания Splash.
  Future<void> start(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    await pumpTestApp(tester, db: db, prefs: prefs);
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
  }

  testWidgets('вход: пустые поля и некорректный email', (tester) async {
    await start(tester);
    await tap(tester, 'login_submit');
    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('login_email')), 'ira@mail');
    await tap(tester, 'login_submit');
    expect(
      find.text('Введите корректный email, например name@mail.ru'),
      findsOneWidget,
    );
    await finish(tester);
  });

  testWidgets('регистрация: слабый пароль и несовпадение паролей', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'go_register');

    await tester.enterText(find.byKey(const Key('reg_name')), 'Ира');
    await tester.enterText(find.byKey(const Key('reg_email')), 'new@mail.ru');
    await tester.enterText(find.byKey(const Key('reg_password')), 'короткий');
    await tester.enterText(find.byKey(const Key('reg_confirm')), 'другой1');
    await tap(tester, 'reg_submit');
    expect(find.text('Пароль должен содержать буквы и цифры'), findsOneWidget);
    expect(find.text('Пароли не совпадают'), findsOneWidget);
    // Остались на экране регистрации.
    expect(find.text('Создать аккаунт'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('регистрация: занятый email показывается под полем', (
    tester,
  ) async {
    await tester.runAsync(seedUser);
    await start(tester);
    await tap(tester, 'go_register');

    await tester.enterText(find.byKey(const Key('reg_name')), 'Ирина');
    await tester.enterText(find.byKey(const Key('reg_email')), 'IRA@mail.ru');
    await tester.enterText(find.byKey(const Key('reg_password')), 'pass12345');
    await tester.enterText(find.byKey(const Key('reg_confirm')), 'pass12345');
    await tap(tester, 'reg_submit');
    expect(
      find.text('Пользователь с таким email уже существует'),
      findsOneWidget,
    );
    expect(find.text('Создать аккаунт'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('автовход: сохранённая сессия ведёт сразу на главную', (
    tester,
  ) async {
    final id = await tester.runAsync(seedUser);
    await start(tester, prefs: {'current_user_id': id!});
    expect(find.text('Привет, Ира!'), findsOneWidget);
    expect(find.text('С возвращением!'), findsNothing);
    await finish(tester);
  });

  testWidgets('сессия удалённого пользователя не даёт войти', (tester) async {
    await start(tester, prefs: {'current_user_id': 999});
    expect(find.text('С возвращением!'), findsOneWidget);
    await finish(tester);
  });
}
