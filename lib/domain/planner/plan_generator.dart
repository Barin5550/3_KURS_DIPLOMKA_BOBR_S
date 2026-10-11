import '../entities/plan.dart';
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'scheduler.dart';
import 'topological_sort.dart';

/// Генератор персонального плана обучения.
///
/// Конвейер из пяти шагов:
/// 1. Направление — граф тем с зависимостями (вход [topics]).
/// 2. Темы, известные по результатам теста ([knownTopicIds]), исключаются.
/// 3. Оставшиеся темы упорядочиваются топологической сортировкой (Кан).
/// 4. Темы раскладываются по учебным дням с лимитом часов ([Scheduler]).
/// 5. Проверяется дедлайн; если он не выполняется, подбирается минимальное
///    число часов в неделю, при котором план в него укладывается.
///    Интервальные повторения добавляет [Scheduler] на шаге 4.
class PlanGenerator {
  const PlanGenerator({this.scheduler = const Scheduler()});

  final Scheduler scheduler;

  /// Максимум часов в неделю, который имеет смысл предлагать (12 ч × 7 дней).
  static const double maxHoursPerWeek = 84;

  PlanResult generate({
    required List<Topic> topics,
    required ScheduleSettings settings,
    Set<String> knownTopicIds = const {},
  }) {
    // Шаг 2.
    final excluded = topics.where((t) => knownTopicIds.contains(t.id)).toList();
    final remaining = topics
        .where((t) => !knownTopicIds.contains(t.id))
        .toList();

    // Шаг 3.
    final ordered = topologicalSort(remaining);

    // Шаг 4.
    final sessions = scheduler.schedule(ordered, settings);
    final finish = lastStudyDate(sessions);

    // Шаг 5.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);

    return PlanResult(
      orderedTopics: ordered,
      excludedTopics: excluded,
      sessions: sessions,
      finishDate: finish,
      deadlineMet: met,
      requiredHoursPerWeek: met
          ? null
          : requiredHoursPerWeek(ordered, settings),
    );
  }

  /// Подбирает минимальное число часов в неделю (с шагом 0,5 ч), при котором
  /// все темы будут изучены не позже дедлайна. Возвращает `null`, если даже
  /// [maxHoursPerWeek] не хватает.
  double? requiredHoursPerWeek(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
  }) {
    final deadline = settings.deadline;
    if (deadline == null) return null;

    for (
      var hours = settings.hoursPerWeek + 0.5;
      hours <= maxHoursPerWeek;
      hours += 0.5
    ) {
      final candidate = settings.copyWith(hoursPerWeek: hours);
      final sessions = scheduler.schedule(
        orderedTopics,
        candidate,
        remainingMinutes: remainingMinutes,
      );
      final finish = lastStudyDate(sessions);
      if (finish == null || !finish.isAfter(deadline)) return hours;
    }
    return null;
  }

  static DateTime? lastStudyDate(List<PlannedSession> sessions) {
    DateTime? last;
    for (final s in sessions) {
      if (s.kind != SessionKind.study) continue;
      if (last == null || s.date.isAfter(last)) last = s.date;
    }
    return last;
  }
}
