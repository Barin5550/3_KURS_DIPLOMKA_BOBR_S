// Перепланирование — перестройка плана, когда пользователь отстал или
// поменял расписание (слой domain, папка planner). Выполненные занятия не
// трогаются, а остаток тем заново раскладывается с сегодняшнего дня.
// Вызывается из PlanService.replan().

import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';
import 'plan_generator.dart';
import 'scheduler.dart';

/// Результат перепланирования.
class ReplanResult {
  /// Создаёт результат; все поля, кроме [requiredHoursPerWeek], обязательны.
  const ReplanResult({
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Новые невыполненные занятия, начиная с сегодняшнего дня.
  final List<PlannedSession> sessions;

  /// Новая дата окончания — день последнего занятия по изучению темы
  /// (`null`, если изучать больше нечего).
  final DateTime? finishDate;

  /// `true`, если план укладывается в дедлайн или дедлайн не задан.
  final bool deadlineMet;

  /// Сколько часов в неделю нужно, чтобы успеть к дедлайну. Заполняется,
  /// только если [deadlineMet] равно `false`; `null` в этом случае значит,
  /// что не успеть даже при максимуме часов.
  final double? requiredHoursPerWeek;
}

/// Перестраивает план, если пользователь отстал или изменил расписание.
///
/// Выполненные занятия остаются на своих местах. Для каждой темы считается,
/// сколько минут уже изучено; остаток заново раскладывается начиная с
/// [today] теми же правилами, что и при генерации. Невыполненные повторения
/// по уже изученным темам переносятся на ближайшие учебные дни.
class Replanner {
  /// Создаёт перепланировщик. [scheduler] можно подменить (например, в
  /// тестах); по умолчанию — стандартный планировщик.
  const Replanner({this.scheduler = const Scheduler()});

  /// Планировщик, который заново раскладывает остаток тем по дням.
  final Scheduler scheduler;

  /// Перестраивает план.
  ///
  /// [orderedTopics] — темы плана в порядке изучения; [sessions] — все
  /// сохранённые занятия плана (выполненные и нет); [settings] — расписание;
  /// [today] — сегодняшняя дата, с неё начинается новое расписание.
  ReplanResult replan({
    required List<Topic> orderedTopics,
    required List<StudySession> sessions,
    required ScheduleSettings settings,
    required DateTime today,
  }) {
    // Новое расписание начинается с сегодняшнего дня (без времени суток).
    final start = dateOnly(today);

    // Считаем, сколько минут по каждой теме уже изучено: складываем
    // минуты выполненных занятий типа «изучение».
    final doneMinutes = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneMinutes[s.topicId] = (doneMinutes[s.topicId] ?? 0) + s.minutes;
      }
    }

    // Остаток по каждой теме = длительность темы − уже изучено.
    // clamp() не даёт остатку уйти ниже 0 и выше полной длительности.
    final remaining = <String, int>{
      for (final t in orderedTopics)
        t.id: (t.minutes - (doneMinutes[t.id] ?? 0)).clamp(0, t.minutes),
    };

    // Невыполненные повторения тем, которые уже изучены полностью.
    // Их не теряем, а передаём планировщику как начальные повторения.
    final pendingReviews = <PendingReview>[
      for (final s in sessions)
        if (!s.isDone &&
            s.kind == SessionKind.review &&
            remaining[s.topicId] == 0)
          PendingReview(
            topicId: s.topicId,
            topicTitle: s.topicTitle,
            category: s.category,
            // Просроченное повторение переносим на сегодня, будущее
            // оставляем на его дату.
            dueDate: s.date.isBefore(start) ? start : s.date,
          ),
    ];

    // Копия настроек, у которой дата старта заменена на сегодня.
    final newSettings = settings.copyWith(startDate: start);
    // Раскладываем остаток тем тем же планировщиком, что и при создании
    // плана: передаём остатки минут и перенесённые повторения.
    final planned = scheduler.schedule(
      orderedTopics,
      newSettings,
      remainingMinutes: remaining,
      initialReviews: pendingReviews,
    );

    // Номера частей продолжают уже выполненные части темы.
    // Сначала считаем, сколько частей каждой темы уже выполнено.
    final doneParts = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneParts[s.topicId] = (doneParts[s.topicId] ?? 0) + 1;
      }
    }
    // Сдвигаем номера: если 2 части темы уже пройдены, новая «часть 1»
    // становится «частью 3», а общее число частей тоже растёт на 2.
    // Повторения и темы без выполненных частей остаются как есть.
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

    // Новая дата окончания — день последнего занятия по изучению.
    final finish = PlanGenerator.lastStudyDate(renumbered);
    // Проверяем дедлайн так же, как при генерации плана.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);
    // Собираем результат. Если не успеваем, подбираем нужное число часов
    // в неделю с учётом того, что часть тем уже изучена.
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
