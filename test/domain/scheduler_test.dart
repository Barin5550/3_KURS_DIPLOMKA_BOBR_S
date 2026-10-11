import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/session.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/scheduler.dart';

Topic t(String id, int minutes) =>
    Topic(id: id, title: id, minutes: minutes, category: 'Тест');

// 12 октября 2026 года — понедельник.
final monday = DateTime(2026, 10, 12);

void main() {
  group('ScheduleSettings.dailyLimitMinutes', () {
    test('делит часы в неделю на число учебных дней', () {
      final s = ScheduleSettings(
        hoursPerWeek: 6,
        studyDays: {1, 3, 5},
        startDate: monday,
      );
      expect(s.dailyLimitMinutes, 120);
    });

    test('округляет до 15 минут и не опускается ниже 30 минут', () {
      expect(
        ScheduleSettings(
          hoursPerWeek: 5,
          studyDays: {1, 2, 3},
          startDate: monday,
        ).dailyLimitMinutes,
        105, // 100 минут → ближайшее кратное 15
      );
      expect(
        ScheduleSettings(
          hoursPerWeek: 1,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ).dailyLimitMinutes,
        30,
      );
    });
  });

  group('Scheduler', () {
    const scheduler = Scheduler(reviewIntervals: []);

    test('ставит занятия только в выбранные дни недели', () {
      final sessions = scheduler.schedule(
        [t('a', 600)],
        ScheduleSettings(
          hoursPerWeek: 4,
          studyDays: {DateTime.tuesday, DateTime.thursday},
          startDate: monday,
        ),
      );
      expect(
        sessions.every(
          (s) =>
              s.date.weekday == DateTime.tuesday ||
              s.date.weekday == DateTime.thursday,
        ),
        isTrue,
      );
      expect(sessions.first.date, DateTime(2026, 10, 13));
    });

    test('не превышает дневной лимит и сохраняет общий объём', () {
      final settings = ScheduleSettings(
        hoursPerWeek: 7,
        studyDays: {1, 2, 3, 4, 5, 6, 7},
        startDate: monday,
      );
      final topics = [t('a', 90), t('b', 150), t('c', 45)];
      final sessions = scheduler.schedule(topics, settings);

      final perDay = <DateTime, int>{};
      for (final s in sessions) {
        perDay[s.date] = (perDay[s.date] ?? 0) + s.minutes;
      }
      expect(perDay.values.every((m) => m <= 60), isTrue);
      expect(sessions.fold<int>(0, (sum, s) => sum + s.minutes), 285);
    });

    test('сохраняет порядок тем и нумерует части', () {
      final sessions = scheduler.schedule(
        [t('a', 150), t('b', 60)],
        ScheduleSettings(
          hoursPerWeek: 7,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ),
      );
      // День 3: 30 минут на конец темы a и 30 минут на начало темы b.
      expect(sessions.map((s) => s.topicId).toList(), [
        'a',
        'a',
        'a',
        'b',
        'b',
      ]);
      expect(sessions.map((s) => s.part).toList(), [1, 2, 3, 1, 2]);
      expect(sessions.first.totalParts, 3);
      expect(sessions.last.totalParts, 2);
      expect(sessions[3].date, sessions[2].date);
    });

    test('не создаёт кусок темы меньше 30 минут, если тема не заканчивается', () {
      // Лимит 60 минут: тема a (45 мин) оставляет 15 минут — b туда не влезает.
      final sessions = scheduler.schedule(
        [t('a', 45), t('b', 120)],
        ScheduleSettings(
          hoursPerWeek: 7,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ),
      );
      expect(sessions[0].date, monday);
      expect(sessions[1].topicId, 'b');
      expect(sessions[1].date, DateTime(2026, 10, 13));
    });

    test('учитывает уже изученные минуты темы', () {
      final sessions = scheduler.schedule(
        [t('a', 120), t('b', 60)],
        ScheduleSettings(
          hoursPerWeek: 14,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ),
        remainingMinutes: {'a': 0, 'b': 30},
      );
      expect(sessions, hasLength(1));
      expect(sessions.single.topicId, 'b');
      expect(sessions.single.minutes, 30);
    });

    test('без учебных дней бросает ошибку', () {
      expect(
        () => scheduler.schedule(
          [t('a', 60)],
          ScheduleSettings(hoursPerWeek: 5, studyDays: {}, startDate: monday),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Интервальные повторения', () {
    const scheduler = Scheduler(reviewIntervals: [1, 3, 7], reviewMinutes: 15);

    test('после темы добавляются повторения через 1, 3 и 7 дней', () {
      final sessions = scheduler.schedule(
        [t('a', 60)],
        ScheduleSettings(
          hoursPerWeek: 7,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ),
      );
      final reviews = sessions
          .where((s) => s.kind == SessionKind.review)
          .map((s) => s.date)
          .toList();
      expect(reviews, [
        DateTime(2026, 10, 13),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 19),
      ]);
      expect(
        sessions.where((s) => s.kind == SessionKind.review).first.minutes,
        15,
      );
    });

    test('повторение в неучебный день переносится на ближайший учебный', () {
      // Учимся только по понедельникам и пятницам.
      final sessions = scheduler.schedule(
        [t('a', 60)],
        ScheduleSettings(
          hoursPerWeek: 2,
          studyDays: {DateTime.monday, DateTime.friday},
          startDate: monday,
        ),
      );
      final reviews = sessions
          .where((s) => s.kind == SessionKind.review)
          .map((s) => s.date)
          .toList();
      // +1 (вт) и +3 (чт) → пятница 16.10, +7 (пн 19.10) — в срок.
      expect(reviews, [
        DateTime(2026, 10, 16),
        DateTime(2026, 10, 16),
        DateTime(2026, 10, 19),
      ]);
    });

    test('повторения занимают время дня раньше новых тем', () {
      final sessions = scheduler.schedule(
        [t('a', 60), t('b', 120)],
        ScheduleSettings(
          hoursPerWeek: 7,
          studyDays: {1, 2, 3, 4, 5, 6, 7},
          startDate: monday,
        ),
      );
      final tuesday = sessions
          .where((s) => s.date == DateTime(2026, 10, 13))
          .toList();
      expect(tuesday.first.kind, SessionKind.review);
      expect(tuesday.last.topicId, 'b');
      expect(tuesday.last.minutes, 45);
    });
  });
}
