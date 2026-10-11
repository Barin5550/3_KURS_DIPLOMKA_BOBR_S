// Общие функции для генераторов скриншотов: шрифты и тестовые данные.

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/note_repository_impl.dart';
import 'package:marshrut/data/repositories/plan_repository_impl.dart';
import 'package:marshrut/data/repositories/topic_repository_impl.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/planner/dates.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';

import '../../test/helpers/test_app.dart';

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

Future<void> loadScreenshotFonts() async {
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
Future<int> seedDemoUser(AppDatabase db) async {
  final user = await testAuthRepository(db)
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
