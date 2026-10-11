import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/plan_repository_impl.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';

import '../helpers/test_app.dart';

/// Адаптивность: все экраны открываются без переполнения (overflow) на
/// телефоне, на телефоне в горизонтальной ориентации и в окне Windows.
/// Ошибка вёрстки (жёлто-чёрная полоса) роняет тест автоматически.
void main() {
  const screens = [
    '/home',
    '/plan',
    '/topics',
    '/stats',
    '/profile',
    '/session/1',
    '/plans',
    '/plan/settings',
    '/pomodoro',
    '/topic/fl_dart_syntax',
    '/topics/custom/new?direction=flutter',
    '/notes',
    '/notes/edit',
    '/profile/edit',
    '/profile/password',
  ];

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
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

  /// Пользователь с готовым планом по Flutter.
  Future<int> seed(AppDatabase db) async {
    final user = await testAuthRepository(db)
        .register(name: 'Ира', email: 'ira@mail.ru', password: 'secret123');
    final flutter = (await fileCatalog().loadDirections()).first;
    await PlanService(
      PlanRepositoryImpl(db),
      clock: () => testToday,
    ).createPlan(
      userId: user.id,
      directionId: flutter.id,
      title: flutter.title,
      topics: flutter.topics,
      settings: ScheduleSettings(
        hoursPerWeek: 6,
        studyDays: const {1, 2, 3, 4, 5},
        startDate: testToday,
      ),
      knownTopicIds: const {},
    );
    return user.id;
  }

  for (final (name, size) in [
    ('телефон', phoneSize),
    ('телефон горизонтально', phoneLandscapeSize),
    ('окно Windows', desktopSize),
  ]) {
    testWidgets('все экраны без переполнения: $name', (tester) async {
      final db = memoryDatabase();
      final userId = await tester.runAsync(() => seed(db));
      await pumpTestApp(
        tester,
        db: db,
        prefs: {'current_user_id': userId!},
        size: size,
      );
      await tester.pump(const Duration(milliseconds: 1600));
      await settle(tester);

      final wide = size.width >= 840;
      expect(find.byType(NavigationRail), wide ? findsOneWidget : findsNothing);
      expect(find.byType(NavigationBar), wide ? findsNothing : findsOneWidget);

      GoRouter router() =>
          GoRouter.of(tester.element(find.byType(Scaffold).first));

      for (final location in screens) {
        router().go(location);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: location);
      }

      // Онбординг: направление → тест → расписание → предпросмотр.
      router().go('/onboarding');
      await settle(tester);
      for (final key in [
        'direction_flutter',
        'test_skip',
        'schedule_generate',
      ]) {
        await tap(tester, find.byKey(Key(key)));
      }
      expect(find.text('Ваш план готов'), findsOneWidget);

      // Экраны входа и регистрации.
      router().go('/profile');
      await settle(tester);
      await tap(tester, find.byKey(const Key('logout_button')));
      await tap(tester, find.text('Выйти').last);
      expect(find.text('С возвращением!'), findsOneWidget);
      router().go('/register');
      await settle(tester);
      expect(find.text('Создать аккаунт'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      await tester.runAsync(db.close);
    });
  }
}
