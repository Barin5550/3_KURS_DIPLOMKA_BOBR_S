import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';
import 'plan_generator.dart';
import 'scheduler.dart';

/// Результат перепланирования.
class ReplanResult {
  const ReplanResult({
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Новые невыполненные занятия, начиная с сегодняшнего дня.
  final List<PlannedSession> sessions;
  final DateTime? finishDate;
  final bool deadlineMet;
  final double? requiredHoursPerWeek;
}

/// Перестраивает план, если пользователь отстал или изменил расписание.
///
/// Выполненные занятия остаются на своих местах. Для каждой темы считается,
/// сколько минут уже изучено; остаток заново раскладывается начиная с
/// [today] теми же правилами, что и при генерации. Невыполненные повторения
/// по уже изученным темам переносятся на ближайшие учебные дни.
class Replanner {
  const Replanner({this.scheduler = const Scheduler()});

  final Scheduler scheduler;

  ReplanResult replan({
    required List<Topic> orderedTopics,
    required List<StudySession> sessions,
    required ScheduleSettings settings,
    required DateTime today,
  }) {
    final start = dateOnly(today);

    final doneMinutes = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneMinutes[s.topicId] = (doneMinutes[s.topicId] ?? 0) + s.minutes;
      }
    }

    final remaining = <String, int>{
      for (final t in orderedTopics)
        t.id: (t.minutes - (doneMinutes[t.id] ?? 0)).clamp(0, t.minutes),
    };

    // Невыполненные повторения тем, которые уже изучены полностью.
    final pendingReviews = <PendingReview>[
      for (final s in sessions)
        if (!s.isDone &&
            s.kind == SessionKind.review &&
            remaining[s.topicId] == 0)
          PendingReview(
            topicId: s.topicId,
            topicTitle: s.topicTitle,
            category: s.category,
            dueDate: s.date.isBefore(start) ? start : s.date,
          ),
    ];

    final newSettings = settings.copyWith(startDate: start);
    final planned = scheduler.schedule(
      orderedTopics,
      newSettings,
      remainingMinutes: remaining,
      initialReviews: pendingReviews,
    );

    // Номера частей продолжают уже выполненные части темы.
    final doneParts = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneParts[s.topicId] = (doneParts[s.topicId] ?? 0) + 1;
      }
    }
    final renumbered = [
      for (final s in planned)
        if (s.kind == SessionKind.study && (doneParts[s.topicId] ?? 0) > 0)
          s.copyWith(
            part: s.part + doneParts[s.topicId]!,
            totalParts: s.totalParts + doneParts[s.topicId]!,
          )
        else
          s,
    ];

    final finish = PlanGenerator.lastStudyDate(renumbered);
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);
    return ReplanResult(
      sessions: renumbered,
      finishDate: finish,
      deadlineMet: met,
      requiredHoursPerWeek: met
          ? null
          : PlanGenerator(scheduler: scheduler).requiredHoursPerWeek(
              orderedTopics,
              newSettings,
              remainingMinutes: remaining,
            ),
    );
  }
}
