// Файл plan.dart — сущности плана обучения.
// Слой: domain. PlanResult возвращает генератор плана (domain/planner) и
// показывает экран предпросмотра; StudyPlan и PlanTopic читает и пишет
// PlanRepositoryImpl (data), а использует PlanService (domain/usecases);
// PlanProgress считается в провайдере planProgressProvider для главной,
// экрана плана и списка планов (presentation).
import 'schedule_settings.dart';
import 'session.dart';
import 'topic.dart';

/// Результат работы генератора плана.
class PlanResult {
  /// Создаёт результат; [requiredHoursPerWeek] необязателен.
  const PlanResult({
    required this.orderedTopics,
    required this.excludedTopics,
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Темы в порядке изучения (после топологической сортировки).
  ///
  /// Топологическая сортировка — такой порядок тем, при котором каждая
  /// тема идёт после всех тем, от которых она зависит.
  final List<Topic> orderedTopics;

  /// Темы, исключённые по результатам диагностического теста.
  final List<Topic> excludedTopics;

  /// Все рассчитанные занятия (изучение и повторения) по датам.
  final List<PlannedSession> sessions;

  /// Дата последнего занятия по изучению новой темы.
  final DateTime? finishDate;

  /// План укладывается в дедлайн (или дедлайн не задан).
  final bool deadlineMet;

  /// Сколько часов в неделю нужно, чтобы успеть к дедлайну.
  /// Заполняется только если [deadlineMet] равно `false`;
  /// `null` при невыполнимом дедлайне.
  final double? requiredHoursPerWeek;

  /// Сумма минут всех занятий-изучений.
  int get studyMinutes => sessions
      // Оставляем только изучение новых тем.
      .where((s) => s.kind == SessionKind.study)
      // Складываем их минуты, начиная с нуля.
      .fold(0, (sum, s) => sum + s.minutes);

  /// Сумма минут всех занятий-повторений.
  int get reviewMinutes => sessions
      // Оставляем только повторения.
      .where((s) => s.kind == SessionKind.review)
      // Складываем их минуты, начиная с нуля.
      .fold(0, (sum, s) => sum + s.minutes);
}

/// Персональный план обучения пользователя.
class StudyPlan {
  /// Создаёт план со всеми полями из базы.
  const StudyPlan({
    required this.id,
    required this.userId,
    required this.directionId,
    required this.title,
    required this.settings,
    required this.knownTopicIds,
    required this.isActive,
    required this.createdAt,
  });

  /// Номер плана в базе данных.
  final int id;

  /// Владелец плана (id пользователя).
  final int userId;

  /// id направления, по которому составлен план.
  final String directionId;

  /// Название плана.
  final String title;

  /// Настройки расписания плана.
  final ScheduleSettings settings;

  /// id тем, которые пользователь уже знает (по диагностическому тесту).
  final Set<String> knownTopicIds;

  /// Текущий (активный) ли это план пользователя.
  final bool isActive;

  /// Когда план создан.
  final DateTime createdAt;
}

/// Тема в составе конкретного плана (снимок на момент создания плана).
class PlanTopic {
  /// Создаёт снимок темы плана.
  const PlanTopic({
    required this.topicId,
    required this.title,
    required this.category,
    required this.minutes,
    required this.level,
    required this.prerequisites,
    required this.position,
  });

  /// id темы.
  final String topicId;

  /// Название темы.
  final String title;

  /// Категория темы.
  final String category;

  /// Длительность темы в минутах.
  final int minutes;

  /// Уровень сложности темы.
  final int level;

  /// id тем, которые нужно изучить раньше этой.
  final List<String> prerequisites;

  /// Порядковый номер темы в плане (по нему темы сортируются).
  final int position;

  /// Превращает снимок обратно в [Topic], чтобы передать его алгоритмам
  /// планировщика (например, при перепланировании).
  Topic toTopic() => Topic(
    id: topicId,
    title: title,
    category: category,
    minutes: minutes,
    level: level,
    prerequisites: prerequisites,
  );
}

/// Сводка прогресса по плану.
class PlanProgress {
  /// Создаёт сводку с готовыми числами.
  const PlanProgress({
    required this.doneStudyMinutes,
    required this.totalStudyMinutes,
    required this.doneSessions,
    required this.totalSessions,
    required this.missedSessions,
    required this.finishDate,
  });

  /// Сколько минут изучения новых тем уже выполнено.
  final int doneStudyMinutes;

  /// Сколько минут изучения новых тем всего в плане.
  final int totalStudyMinutes;

  /// Сколько занятий (любого типа) выполнено.
  final int doneSessions;

  /// Сколько всего занятий в плане.
  final int totalSessions;

  /// Сколько занятий пропущено.
  final int missedSessions;

  /// Дата последнего занятия-изучения (ожидаемое окончание плана).
  final DateTime? finishDate;

  /// Доля выполненного изучения от 0 до 1 (для индикаторов прогресса).
  double get ratio =>
      totalStudyMinutes == 0 ? 0 : doneStudyMinutes / totalStudyMinutes;

  /// Считает сводку по списку занятий плана; [today] нужен, чтобы
  /// определить пропущенные занятия.
  factory PlanProgress.fromSessions(
    List<StudySession> sessions,
    DateTime today,
  ) {
    // Счётчики: выполненные минуты, все минуты изучения,
    // выполненные занятия, пропущенные занятия.
    var done = 0;
    var total = 0;
    var doneCount = 0;
    var missed = 0;
    // Самая поздняя дата занятия-изучения.
    DateTime? finish;
    // Проходим по всем занятиям один раз.
    for (final s in sessions) {
      // Минуты и дату окончания считаем только по изучению новых тем.
      if (s.kind == SessionKind.study) {
        total += s.minutes;
        if (s.isDone) done += s.minutes;
        // Запоминаем самую позднюю дату.
        if (finish == null || s.date.isAfter(finish)) finish = s.date;
      }
      // Выполненные и пропущенные считаем по всем занятиям.
      if (s.isDone) doneCount++;
      if (s.isMissed(today)) missed++;
    }
    // Собираем итоговую сводку.
    return PlanProgress(
      doneStudyMinutes: done,
      totalStudyMinutes: total,
      doneSessions: doneCount,
      totalSessions: sessions.length,
      missedSessions: missed,
      finishDate: finish,
    );
  }
}
