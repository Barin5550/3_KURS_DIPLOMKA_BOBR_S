import 'dart:collection';

import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';

/// Повторение, которое нужно провести не раньше [dueDate].
class PendingReview {
  const PendingReview({
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.dueDate,
  });

  final String topicId;
  final String topicTitle;
  final String category;
  final DateTime dueDate;
}

/// Раскладывает упорядоченные темы по учебным дням.
///
/// Алгоритм моделирует календарь день за днём, начиная с даты старта:
/// 1. Невыбранные дни недели пропускаются.
/// 2. В учебный день доступно [ScheduleSettings.dailyLimitMinutes] минут.
/// 3. Сначала в день ставятся повторения, срок которых наступил
///    (по [reviewMinutes] минут каждое).
/// 4. Оставшееся время заполняется текущей темой. Тема дробится на части,
///    но не мельче [minChunkMinutes], если остаток темы больше этого порога.
/// 5. Когда тема закончена, планируются повторения через [reviewIntervals]
///    календарных дней (по кривой забывания Эббингауза: 1, 3, 7 дней).
///    Повторение, выпавшее на неучебный день, переносится на ближайший учебный.
class Scheduler {
  const Scheduler({
    this.reviewIntervals = const [1, 3, 7],
    this.reviewMinutes = 15,
    this.minChunkMinutes = 30,
    this.maxDays = 3650,
  });

  final List<int> reviewIntervals;
  final int reviewMinutes;
  final int minChunkMinutes;

  /// Защита от бесконечного цикла при некорректных настройках.
  final int maxDays;

  /// [remainingMinutes] позволяет передать остаток по теме, если часть уже
  /// изучена (используется при перепланировании). По умолчанию —
  /// полная длительность темы.
  /// [initialReviews] — повторения, перенесённые из прошлого расписания.
  List<PlannedSession> schedule(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
    List<PendingReview> initialReviews = const [],
  }) {
    final dailyLimit = settings.dailyLimitMinutes;
    if (settings.studyDays.isEmpty || dailyLimit <= 0) {
      throw ArgumentError('Нужно выбрать хотя бы один учебный день');
    }

    final work = Queue<_TopicWork>()
      ..addAll(
        orderedTopics
            .map((t) => _TopicWork(t, remainingMinutes[t.id] ?? t.minutes))
            .where((w) => w.remaining > 0),
      );
    final reviews = [...initialReviews]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final sessions = <PlannedSession>[];

    var day = dateOnly(settings.startDate);
    for (var i = 0; i < maxDays; i++, day = addDays(day, 1)) {
      if (work.isEmpty && reviews.isEmpty) break;
      if (!settings.studyDays.contains(day.weekday)) continue;

      var capacity = dailyLimit;

      // Шаг 3: повторения, срок которых наступил.
      final due = reviews.where((r) => !r.dueDate.isAfter(day)).toList();
      for (final review in due) {
        if (capacity < reviewMinutes) break;
        sessions.add(
          PlannedSession(
            topicId: review.topicId,
            topicTitle: review.topicTitle,
            category: review.category,
            date: day,
            minutes: reviewMinutes,
            kind: SessionKind.review,
          ),
        );
        capacity -= reviewMinutes;
        reviews.remove(review);
      }

      // Шаг 4: новые темы.
      while (work.isNotEmpty && capacity > 0) {
        final current = work.first;
        final chunk = capacity < current.remaining
            ? capacity
            : current.remaining;
        if (chunk < minChunkMinutes && chunk < current.remaining) break;

        sessions.add(
          PlannedSession(
            topicId: current.topic.id,
            topicTitle: current.topic.title,
            category: current.topic.category,
            date: day,
            minutes: chunk,
            kind: SessionKind.study,
          ),
        );
        capacity -= chunk;
        current.remaining -= chunk;

        if (current.remaining == 0) {
          work.removeFirst();
          // Шаг 5: повторения после завершения темы.
          for (final interval in reviewIntervals) {
            reviews.add(
              PendingReview(
                topicId: current.topic.id,
                topicTitle: current.topic.title,
                category: current.topic.category,
                dueDate: addDays(day, interval),
              ),
            );
          }
          reviews.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        }
      }
    }

    return _numberParts(sessions);
  }

  /// Проставляет номер части для тем, разбитых на несколько занятий.
  List<PlannedSession> _numberParts(List<PlannedSession> sessions) {
    final totals = <String, int>{};
    for (final s in sessions) {
      if (s.kind == SessionKind.study) {
        totals[s.topicId] = (totals[s.topicId] ?? 0) + 1;
      }
    }
    final counters = <String, int>{};
    return [
      for (final s in sessions)
        if (s.kind == SessionKind.study)
          s.copyWith(
            part: counters[s.topicId] = (counters[s.topicId] ?? 0) + 1,
            totalParts: totals[s.topicId],
          )
        else
          s,
    ];
  }
}

class _TopicWork {
  _TopicWork(this.topic, this.remaining);

  final Topic topic;
  int remaining;
}
