import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/session.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/plan_generator.dart';
import 'package:marshrut/domain/planner/scheduler.dart';
import 'package:marshrut/domain/planner/topological_sort.dart';

Topic t(String id, int minutes, [List<String> deps = const []]) => Topic(
  id: id,
  title: id,
  minutes: minutes,
  category: 'Тест',
  prerequisites: deps,
);

final monday = DateTime(2026, 10, 12);
final everyDay = {1, 2, 3, 4, 5, 6, 7};

void main() {
  final topics = [
    t('dart', 120),
    t('widgets', 120, ['dart']),
    t('state', 120, ['widgets']),
    t('tests', 60, ['state']),
  ];
  const generator = PlanGenerator(scheduler: Scheduler(reviewIntervals: []));

  test('исключает известные темы и сохраняет порядок зависимостей', () {
    final result = generator.generate(
      topics: topics,
      settings: ScheduleSettings(
        hoursPerWeek: 7,
        studyDays: everyDay,
        startDate: monday,
      ),
      knownTopicIds: {'dart'},
    );

    expect(result.excludedTopics.map((t) => t.id), ['dart']);
    expect(result.orderedTopics.map((t) => t.id), ['widgets', 'state', 'tests']);
    expect(result.sessions.any((s) => s.topicId == 'dart'), isFalse);
    expect(result.studyMinutes, 300);
  });

  test('без дедлайна план всегда «укладывается»', () {
    final result = generator.generate(
      topics: topics,
      settings: ScheduleSettings(
        hoursPerWeek: 1,
        studyDays: {DateTime.monday},
        startDate: monday,
      ),
    );
    expect(result.deadlineMet, isTrue);
    expect(result.requiredHoursPerWeek, isNull);
  });

  test('дата окончания — день последнего занятия по новой теме', () {
    // 420 минут по 60 в день → 7 дней: 12.10 … 18.10.
    final result = generator.generate(
      topics: topics,
      settings: ScheduleSettings(
        hoursPerWeek: 7,
        studyDays: everyDay,
        startDate: monday,
      ),
    );
    expect(result.finishDate, DateTime(2026, 10, 18));
  });

  test('если дедлайн не выполняется, предлагает нужное число часов', () {
    final settings = ScheduleSettings(
      hoursPerWeek: 7,
      studyDays: everyDay,
      startDate: monday,
      deadline: DateTime(2026, 10, 15), // 4 дня на 420 минут
    );
    final result = generator.generate(topics: topics, settings: settings);

    expect(result.deadlineMet, isFalse);
    expect(result.requiredHoursPerWeek, isNotNull);

    final fixed = generator.generate(
      topics: topics,
      settings: settings.copyWith(hoursPerWeek: result.requiredHoursPerWeek),
    );
    expect(fixed.deadlineMet, isTrue);

    final almost = generator.generate(
      topics: topics,
      settings: settings.copyWith(
        hoursPerWeek: result.requiredHoursPerWeek! - 0.5,
      ),
    );
    expect(almost.deadlineMet, isFalse, reason: 'подобран минимум');
  });

  test('невыполнимый дедлайн даёт requiredHoursPerWeek == null', () {
    final result = generator.generate(
      topics: [t('huge', 100 * 60)],
      settings: ScheduleSettings(
        hoursPerWeek: 5,
        studyDays: {DateTime.monday},
        startDate: monday,
        deadline: monday,
      ),
    );
    expect(result.deadlineMet, isFalse);
    expect(result.requiredHoursPerWeek, isNull);
  });

  test('с повторениями по умолчанию появляются занятия типа review', () {
    final result = const PlanGenerator().generate(
      topics: topics,
      settings: ScheduleSettings(
        hoursPerWeek: 7,
        studyDays: everyDay,
        startDate: monday,
      ),
    );
    final reviews = result.sessions.where((s) => s.kind == SessionKind.review);
    expect(reviews.length, topics.length * 3);
    expect(result.reviewMinutes, topics.length * 3 * 15);
  });

  test('цикл в данных пробрасывается как CycleDetectedException', () {
    expect(
      () => generator.generate(
        topics: [
          t('a', 60, ['b']),
          t('b', 60, ['a']),
        ],
        settings: ScheduleSettings(
          hoursPerWeek: 7,
          studyDays: everyDay,
          startDate: monday,
        ),
      ),
      throwsA(isA<CycleDetectedException>()),
    );
  });
}
