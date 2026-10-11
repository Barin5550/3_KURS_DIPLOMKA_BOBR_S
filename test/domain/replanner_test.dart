import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/session.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/replanner.dart';
import 'package:marshrut/domain/planner/scheduler.dart';

Topic t(String id, int minutes) =>
    Topic(id: id, title: id, minutes: minutes, category: 'Тест');

var _id = 0;
StudySession s(
  String topicId,
  DateTime date,
  int minutes, {
  bool done = false,
  SessionKind kind = SessionKind.study,
}) => StudySession(
  id: ++_id,
  planId: 1,
  topicId: topicId,
  topicTitle: topicId,
  category: 'Тест',
  date: date,
  minutes: minutes,
  kind: kind,
  part: 1,
  totalParts: 1,
  isDone: done,
);

void main() {
  final everyDay = {1, 2, 3, 4, 5, 6, 7};
  final settings = ScheduleSettings(
    hoursPerWeek: 7,
    studyDays: everyDay,
    startDate: DateTime(2026, 10, 12),
  );
  final topics = [t('a', 120), t('b', 60)];

  test('пропущенные занятия переносятся на сегодня и дальше', () {
    final today = DateTime(2026, 10, 15);
    final result = const Replanner(
      scheduler: Scheduler(reviewIntervals: []),
    ).replan(
      orderedTopics: topics,
      sessions: [
        s('a', DateTime(2026, 10, 12), 60, done: true),
        s('a', DateTime(2026, 10, 13), 60), // пропущено
        s('b', DateTime(2026, 10, 14), 60), // пропущено
      ],
      settings: settings,
      today: today,
    );

    expect(result.sessions.every((x) => !x.date.isBefore(today)), isTrue);
    expect(result.sessions.map((x) => x.topicId), ['a', 'b']);
    expect(result.sessions.first.date, today);
    // Осталось 60 минут темы a: это вторая часть из двух.
    expect(result.sessions.first.minutes, 60);
    expect(result.sessions.first.part, 2);
    expect(result.sessions.first.totalParts, 2);
    expect(result.finishDate, DateTime(2026, 10, 16));
  });

  test('полностью изученные темы не попадают в новый план', () {
    final result = const Replanner(
      scheduler: Scheduler(reviewIntervals: []),
    ).replan(
      orderedTopics: topics,
      sessions: [
        s('a', DateTime(2026, 10, 12), 60, done: true),
        s('a', DateTime(2026, 10, 13), 60, done: true),
      ],
      settings: settings,
      today: DateTime(2026, 10, 14),
    );
    expect(result.sessions.map((x) => x.topicId), ['b']);
  });

  test('невыполненные повторения изученных тем переносятся на сегодня', () {
    final today = DateTime(2026, 10, 20);
    final result = const Replanner().replan(
      orderedTopics: [t('a', 60)],
      sessions: [
        s('a', DateTime(2026, 10, 12), 60, done: true),
        s('a', DateTime(2026, 10, 13), 15, kind: SessionKind.review),
        s('a', DateTime(2026, 10, 25), 15, kind: SessionKind.review),
      ],
      settings: settings,
      today: today,
    );
    final reviews = result.sessions.map((x) => x.date).toList();
    expect(reviews, [today, DateTime(2026, 10, 25)]);
  });

  test('проверяет дедлайн после перепланирования', () {
    final result = const Replanner(
      scheduler: Scheduler(reviewIntervals: []),
    ).replan(
      orderedTopics: topics,
      sessions: const [],
      settings: settings.copyWith(deadline: DateTime(2026, 10, 20)),
      today: DateTime(2026, 10, 20),
    );
    expect(result.deadlineMet, isFalse);
    // 180 минут за один день: нужно 20,5 ч/нед (175,7 мин/день → округление до 180).
    expect(result.requiredHoursPerWeek, 20.5);
  });
}
