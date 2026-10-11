import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/plan_repository_impl.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';
import 'package:marshrut/presentation/widgets/common.dart';

import '../helpers/test_app.dart';

/// Функции 2 семестра через интерфейс: заметки, свои темы и избранное,
/// управление планами, статистика и Pomodoro.
void main() {
  late AppDatabase db;
  late int planId;

  setUp(() => db = memoryDatabase());

  /// Пользователь с планом по Flutter; [done] первых занятий выполнены.
  Future<int> seed({int done = 0}) async {
    final user = await testAuthRepository(db)
        .register(name: 'Ира', email: 'ira@mail.ru', password: 'secret123');
    final flutter = (await fileCatalog().loadDirections()).first;
    final plans = PlanRepositoryImpl(db);
    planId = await PlanService(plans, clock: () => testToday).createPlan(
      userId: user.id,
      directionId: flutter.id,
      title: 'Flutter',
      topics: flutter.topics,
      settings: ScheduleSettings(
        hoursPerWeek: 6,
        studyDays: const {1, 2, 3, 4, 5},
        startDate: testToday,
      ),
      knownTopicIds: const {},
    );
    for (final s in (await plans.sessions(planId)).take(done)) {
      await plans.setSessionDone(s.id, done: true);
    }
    return user.id;
  }

  Future<void> start(WidgetTester tester, {int done = 0}) async {
    final userId = await tester.runAsync(() => seed(done: done));
    await pumpTestApp(tester, db: db, prefs: {'current_user_id': userId!});
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);
  }

  void go(WidgetTester tester, String location) =>
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    // Без кадра после прокрутки tap() берёт старые координаты.
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
  }

  testWidgets('заметки: создание, поиск, изменение и удаление', (tester) async {
    await start(tester);
    go(tester, '/notes');
    await settle(tester);
    expect(find.byType(EmptyState), findsWidgets);

    // Пустая форма не сохраняется.
    await tap(tester, find.byKey(const Key('add_note')));
    await tap(tester, find.byKey(const Key('note_save')));
    expect(find.text('Заполните текст заметки'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('note_title')), 'Виджеты');
    await tester.enterText(
      find.byKey(const Key('note_body')),
      'StatelessWidget не хранит состояние',
    );
    await tap(tester, find.byKey(const Key('note_save')));
    expect(find.text('Виджеты'), findsOneWidget);

    // Поиск без совпадений.
    await tester.enterText(find.byType(TextField).first, 'riverpod');
    await settle(tester);
    expect(find.text('Виджеты'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'state');
    await settle(tester);
    expect(find.text('Виджеты'), findsOneWidget);

    // Изменение.
    await tap(tester, find.text('Виджеты'));
    await tester.enterText(
      find.byKey(const Key('note_title')),
      'Виджеты Flutter',
    );
    await tap(tester, find.byKey(const Key('note_save')));
    await tester.enterText(find.byType(TextField).first, '');
    await settle(tester);
    expect(find.text('Виджеты Flutter'), findsOneWidget);

    // Удаление с подтверждением.
    await tap(tester, find.text('Виджеты Flutter'));
    await tap(tester, find.byKey(const Key('delete_note')));
    await tap(tester, find.text('Удалить').last);
    expect(find.text('Виджеты Flutter'), findsNothing);
    expect(await tester.runAsync(() => db.select(db.notes).get()), isEmpty);
    await finish(tester);
  });

  testWidgets('своя тема: создание, избранное и удаление', (tester) async {
    await start(tester);
    go(tester, '/topics');
    await settle(tester);

    await tap(tester, find.byKey(const Key('add_custom_topic')));
    await tester.enterText(
      find.byKey(const Key('topic_title')),
      'Анимации Rive',
    );
    await tester.enterText(find.byKey(const Key('topic_hours')), '1,5');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Категория'),
      'Интерфейс',
    );
    await tap(tester, find.byKey(const Key('topic_save')));

    // Тема видна в каталоге направления и находится поиском.
    await tester.enterText(find.byKey(const Key('topics_search')), 'rive');
    await settle(tester);
    expect(find.text('Анимации Rive'), findsOneWidget);

    await tap(tester, find.text('Анимации Rive'));
    await tap(tester, find.byKey(const Key('favorite_toggle')));
    expect(
      await tester.runAsync(() => db.select(db.favorites).get()),
      hasLength(1),
    );

    await tap(tester, find.byKey(const Key('delete_custom_topic')));
    await tap(tester, find.text('Удалить').last);
    expect(
      await tester.runAsync(() => db.select(db.customTopics).get()),
      isEmpty,
    );
    // Удаление темы чистит и избранное.
    expect(await tester.runAsync(() => db.select(db.favorites).get()), isEmpty);
    await finish(tester);
  });

  testWidgets('мои планы: переименование и удаление', (tester) async {
    await start(tester);
    go(tester, '/plans');
    await settle(tester);

    await tap(tester, find.byKey(Key('plan_menu_$planId')));
    await tap(tester, find.text('Переименовать'));
    await tester.enterText(find.byKey(const Key('rename_field')), '');
    await tap(tester, find.byKey(const Key('rename_save')));
    expect(find.text('Название плана'), findsOneWidget, reason: 'пустое имя');
    await tester.enterText(
      find.byKey(const Key('rename_field')),
      'Flutter к сессии',
    );
    await tap(tester, find.byKey(const Key('rename_save')));
    expect(find.text('Flutter к сессии'), findsOneWidget);

    await tap(tester, find.byKey(Key('plan_menu_$planId')));
    await tap(tester, find.text('Удалить'));
    await tap(tester, find.text('Удалить').last);
    expect(find.text('Flutter к сессии'), findsNothing);
    expect(await tester.runAsync(() => db.select(db.plans).get()), isEmpty);
    expect(await tester.runAsync(() => db.select(db.sessions).get()), isEmpty);
    await finish(tester);
  });

  testWidgets('статистика: пусто без занятий', (tester) async {
    await start(tester);
    go(tester, '/stats');
    await settle(tester);
    expect(find.byKey(const Key('stats_empty')), findsOneWidget);
    await finish(tester);
  });

  testWidgets('статистика: графики и история по выполненным занятиям', (
    tester,
  ) async {
    await start(tester, done: 3);
    go(tester, '/stats');
    await settle(tester);
    expect(find.byKey(const Key('stats_empty')), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('История'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('История'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Pomodoro: старт, пауза и сброс', (tester) async {
    await start(tester);
    go(tester, '/pomodoro');
    await settle(tester);
    expect(find.text('25:00'), findsOneWidget);

    await tap(tester, find.byKey(const Key('pomodoro_start')));
    expect(find.text('Пауза'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('25:00'), findsNothing, reason: 'время пошло');

    await tap(tester, find.byKey(const Key('pomodoro_start')));
    expect(find.text('Старт'), findsOneWidget);
    await tap(tester, find.text('Сброс'));
    expect(find.text('25:00'), findsOneWidget);
    await finish(tester);
  });
}
