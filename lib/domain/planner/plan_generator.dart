// Генератор персонального плана обучения (слой domain, папка planner).
// Собирает вместе все шаги построения плана: исключение известных тем,
// сортировку Кана, раскладку по дням (Scheduler) и проверку дедлайна.
// Используется в PlanService (предпросмотр и создание плана) и в Replanner.

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
  /// Создаёт генератор. [scheduler] можно передать свой (например, в
  /// тестах); по умолчанию — стандартный планировщик с повторениями
  /// через 1, 3 и 7 дней.
  const PlanGenerator({this.scheduler = const Scheduler()});

  /// Планировщик, который раскладывает темы по дням (шаг 4).
  final Scheduler scheduler;

  /// Максимум часов в неделю, который имеет смысл предлагать (12 ч × 7 дней).
  static const double maxHoursPerWeek = 84;

  /// Строит план по темам направления [topics] и расписанию [settings].
  ///
  /// [knownTopicIds] — id тем, которые пользователь уже знает по тесту; они
  /// не попадают в план. Возвращает [PlanResult]: порядок тем, занятия по
  /// датам, дату окончания и признак того, успевает ли план к дедлайну.
  PlanResult generate({
    required List<Topic> topics,
    required ScheduleSettings settings,
    Set<String> knownTopicIds = const {},
  }) {
    // Шаг 2.
    // Темы, которые пользователь уже знает, откладываем отдельно, чтобы
    // показать их на экране как исключённые.
    final excluded = topics.where((t) => knownTopicIds.contains(t.id)).toList();
    // Все остальные темы — их и нужно изучать.
    final remaining = topics
        .where((t) => !knownTopicIds.contains(t.id))
        .toList();

    // Шаг 3.
    // Упорядочиваем темы алгоритмом Кана: каждая тема встаёт после всех
    // тем, от которых она зависит.
    final ordered = topologicalSort(remaining);

    // Шаг 4.
    // Раскладываем темы по учебным дням (повторения добавятся там же).
    final sessions = scheduler.schedule(ordered, settings);
    // День последнего занятия по новой теме — дата окончания плана.
    final finish = lastStudyDate(sessions);

    // Шаг 5.
    // Дедлайн выполнен, если его нет, если занятий нет вообще или если
    // план заканчивается не позже дедлайна.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);

    // Собираем результат. Если дедлайн не выполнен, дополнительно считаем,
    // сколько часов в неделю нужно, чтобы успеть.
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
  ///
  /// [remainingMinutes] — остаток минут по темам; его передаёт Replanner,
  /// когда часть тем уже изучена.
  double? requiredHoursPerWeek(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
  }) {
    // Без дедлайна подбирать нечего.
    final deadline = settings.deadline;
    if (deadline == null) return null;

    // Простой перебор: начинаем с текущих часов + 0,5 и прибавляем
    // по 0,5 ч, пока не дойдём до максимума.
    for (
      var hours = settings.hoursPerWeek + 0.5;
      hours <= maxHoursPerWeek;
      hours += 0.5
    ) {
      // Копия настроек, в которой изменено только число часов в неделю.
      final candidate = settings.copyWith(hoursPerWeek: hours);
      // Пробно раскладываем те же темы с новым дневным лимитом.
      final sessions = scheduler.schedule(
        orderedTopics,
        candidate,
        remainingMinutes: remainingMinutes,
      );
      // Смотрим, когда закончится такой пробный план.
      final finish = lastStudyDate(sessions);
      // Успеваем к дедлайну — это и есть минимальное подходящее значение.
      if (finish == null || !finish.isAfter(deadline)) return hours;
    }
    // Даже максимума не хватает — дедлайн невыполним.
    return null;
  }

  /// Находит дату последнего занятия типа «изучение»; повторения не
  /// учитываются. Возвращает `null`, если таких занятий нет.
  /// Метод статический (не требует объекта), его вызывает и Replanner.
  static DateTime? lastStudyDate(List<PlannedSession> sessions) {
    // Самая поздняя найденная дата (пока ничего не нашли).
    DateTime? last;
    // Просматриваем все занятия по очереди.
    for (final s in sessions) {
      // Повторения пропускаем: план закончен, когда изучена последняя тема.
      if (s.kind != SessionKind.study) continue;
      // Запоминаем дату, если она позже уже найденной.
      if (last == null || s.date.isAfter(last)) last = s.date;
    }
    // Возвращаем самую позднюю дату изучения.
    return last;
  }
}
