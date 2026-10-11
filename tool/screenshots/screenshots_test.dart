// Генератор скриншотов экранов для отчёта по курсовой работе.
//
// Запуск:  flutter test tool/screenshots/screenshots_test.dart
// Результат: docs/coursework/screenshots/*.png
//
// Приложение запускается с тестовыми данными (база в памяти, фиксированная
// дата 12.10.2026) и настоящими шрифтами Roboto и Material Icons из Flutter SDK.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/auth_repository_impl.dart';
import 'package:marshrut/data/repositories/note_repository_impl.dart';
import 'package:marshrut/data/repositories/plan_repository_impl.dart';
import 'package:marshrut/data/repositories/topic_repository_impl.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/planner/dates.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';

import '../../test/helpers/test_app.dart';

const _outDir = 'docs/coursework/screenshots';
const _ratio = 2.75;
final _boundary = GlobalKey();

/// Папка со шрифтами Material внутри Flutter SDK (рядом с flutter_tester).
Directory _materialFonts() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    final candidate = Directory('${dir.path}/material_fonts');
    if (candidate.existsSync()) return candidate;
    final nested = Directory('${dir.path}/artifacts/material_fonts');
    if (nested.existsSync()) return nested;
    dir = dir.parent;
  }
  throw StateError('Не найдены шрифты Material во Flutter SDK');
}

Future<void> _loadFonts() async {
  final dir = _materialFonts();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final name in files) {
      final file = File('${dir.path}/$name');
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  const roboto = [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ];
  await load('Roboto', roboto);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// Пользователь с планом, начатым 4 недели назад: часть занятий выполнена,
/// два пропущены, есть заметки, избранное, своя тема и «помидоры».
Future<int> _seed(AppDatabase db) async {
  final user = await AuthRepositoryImpl(db)
      .register(name: 'Алия', email: 'aliya@mail.ru', password: 'flutter2026');
  final directions = await fileCatalog().loadDirections();
  final flutter = directions.first;
  final plans = PlanRepositoryImpl(db);
  final service = PlanService(plans, clock: () => testToday);
  final start = addDays(dateOnly(testToday), -28);
  final planId = await service.createPlan(
    userId: user.id,
    directionId: flutter.id,
    title: flutter.title,
    topics: flutter.topics,
    settings: ScheduleSettings(
      hoursPerWeek: 6,
      studyDays: const {1, 2, 3, 4, 5},
      startDate: start,
      deadline: DateTime(2027, 3, 1),
    ),
    knownTopicIds: const {'fl_dart_syntax'},
  );
  // Второй план — по английскому языку (для экрана «Мои планы»).
  final english = directions.firstWhere((d) => d.id == 'english');
  await service.createPlan(
    userId: user.id,
    directionId: english.id,
    title: english.title,
    topics: english.topics,
    settings: ScheduleSettings(
      hoursPerWeek: 3,
      studyDays: const {2, 4, 6},
      startDate: dateOnly(testToday),
    ),
    knownTopicIds: const {},
  );
  await plans.setActive(user.id, planId);

  final sessions = await plans.sessions(planId);
  final today = dateOnly(testToday);
  final past = sessions.where((s) => s.date.isBefore(today)).toList();
  for (final (i, s) in past.indexed) {
    // Два последних прошедших занятия оставляем пропущенными.
    if (i >= past.length - 2) break;
    await (db.update(db.sessions)..where((r) => r.id.equals(s.id))).write(
      SessionsCompanion(
        isDone: const Value(true),
        completedAt: Value(s.date.add(const Duration(hours: 19))),
      ),
    );
  }

  for (var d = 1; d <= 20; d += 2) {
    await db
        .into(db.pomodoroLogs)
        .insert(
          PomodoroLogsCompanion.insert(
            userId: user.id,
            minutes: 25,
            topicTitle: const Value('Виджеты и вёрстка'),
            completedAt: today.subtract(Duration(days: d, hours: -18)),
          ),
        );
  }

  final notes = NoteRepositoryImpl(db);
  await notes.createNote(
    userId: user.id,
    title: 'StatelessWidget и StatefulWidget',
    body:
        'Stateless — без изменяемого состояния. Stateful хранит State, '
        'setState перерисовывает виджет.',
    topicId: 'fl_widgets',
    topicTitle: 'Виджеты',
  );
  await notes.createNote(
    userId: user.id,
    title: 'План на неделю',
    body: 'Повторить async/await, сделать экран входа.',
  );

  final topics = TopicRepositoryImpl(db);
  await topics.toggleFavorite(user.id, 'fl_widgets');
  await topics.toggleFavorite(user.id, 'fl_state_riverpod');
  await topics.createCustomTopic(
    userId: user.id,
    directionId: 'flutter',
    title: 'Анимации',
    description: 'AnimatedContainer, Hero, AnimationController',
    minutes: 120,
    category: 'Интерфейс',
    prerequisites: const ['fl_widgets'],
  );
  return user.id;
}

void main() {
  testWidgets('скриншоты экранов', (tester) async {
    // В тестах тени по умолчанию рисуются чёрной рамкой; для скриншотов
    // включаем настоящие тени.
    debugDisableShadows = false;
    await tester.runAsync(_loadFonts);
    Directory(_outDir).createSync(recursive: true);

    final db = memoryDatabase();
    await tester.runAsync(() => _seed(db));
    final overrides = await tester.runAsync(() => testOverrides(db: db));

    Future<void> setSize(Size size) async {
      tester.view.devicePixelRatio = _ratio;
      tester.view.physicalSize = size * _ratio;
      await tester.pump();
    }

    await setSize(phoneSize);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ProviderScope(overrides: overrides!, child: const MarshrutApp()),
      ),
    );

    Future<void> shot(String name) async {
      await settle(tester, rounds: 6);
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_outDir/$name.png').writeAsBytesSync(bytes!);
    }

    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await settle(tester);
    }

    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> go(String location) async {
      router().go(location);
      await settle(tester);
    }

    // Splash: снимок до автоматического перехода.
    await tester.pump(const Duration(milliseconds: 300));
    await shot('01_splash');
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);

    await shot('02_login');
    await tap(find.byKey(const Key('go_register')));
    await tap(find.byKey(const Key('reg_submit')));
    await shot('03_register_validation');
    await go('/login');
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'aliya@mail.ru',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong123');
    await tap(find.byKey(const Key('login_submit')));
    await shot('04_login_error');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'flutter2026',
    );
    await tap(find.byKey(const Key('login_submit')));

    await shot('05_home');
    await go('/plan');
    await shot('06_plan');
    final sessionTile = find.byKey(const Key('session_tile_first'));
    if (sessionTile.evaluate().isNotEmpty) await tap(sessionTile);
    await go('/topics');
    await shot('07_topics');
    await go('/topic/fl_widgets');
    await shot('08_topic');
    await go('/stats');
    await shot('09_stats');
    await go('/profile');
    await shot('10_profile');
    await go('/plans');
    await shot('11_plans');
    await go('/pomodoro');
    await shot('12_pomodoro');
    await go('/notes');
    await shot('13_notes');
    await go('/session/30');
    await shot('14_session');
    await go('/plan/settings');
    await shot('15_plan_settings');

    // Онбординг нового плана.
    await go('/onboarding');
    await shot('16_direction');
    await tap(find.byKey(const Key('direction_python')));
    await tap(find.byKey(const Key('option_1')));
    await shot('17_diagnostic');
    await tap(find.byKey(const Key('test_skip')));
    await shot('18_schedule');
    await tap(find.byKey(const Key('schedule_generate')));
    await shot('19_preview');

    // Тёмная тема.
    await go('/profile');
    await tap(find.byIcon(Icons.dark_mode));
    await go('/home');
    await shot('20_home_dark');
    await go('/stats');
    await shot('21_stats_dark');
    await go('/profile');
    await tap(find.byIcon(Icons.light_mode));

    // Окно Windows и телефон в горизонтальной ориентации.
    await setSize(desktopSize);
    await go('/home');
    await shot('22_desktop_home');
    await go('/plan');
    await shot('23_desktop_plan');
    await setSize(phoneLandscapeSize);
    await go('/stats');
    await shot('24_landscape_stats');

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
    debugDisableShadows = true;
  });
}
