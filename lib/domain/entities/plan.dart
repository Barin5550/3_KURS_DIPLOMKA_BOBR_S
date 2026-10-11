import 'schedule_settings.dart';
import 'session.dart';
import 'topic.dart';

/// Результат работы генератора плана.
class PlanResult {
  const PlanResult({
    required this.orderedTopics,
    required this.excludedTopics,
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Темы в порядке изучения (после топологической сортировки).
  final List<Topic> orderedTopics;

  /// Темы, исключённые по результатам диагностического теста.
  final List<Topic> excludedTopics;

  final List<PlannedSession> sessions;

  /// Дата последнего занятия по изучению новой темы.
  final DateTime? finishDate;

  /// План укладывается в дедлайн (или дедлайн не задан).
  final bool deadlineMet;

  /// Сколько часов в неделю нужно, чтобы успеть к дедлайну.
  /// Заполняется только если [deadlineMet] равно `false`;
  /// `null` при невыполнимом дедлайне.
  final double? requiredHoursPerWeek;

  int get studyMinutes => sessions
      .where((s) => s.kind == SessionKind.study)
      .fold(0, (sum, s) => sum + s.minutes);

  int get reviewMinutes => sessions
      .where((s) => s.kind == SessionKind.review)
      .fold(0, (sum, s) => sum + s.minutes);
}

/// Персональный план обучения пользователя.
class StudyPlan {
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

  final int id;
  final int userId;
  final String directionId;
  final String title;
  final ScheduleSettings settings;
  final Set<String> knownTopicIds;
  final bool isActive;
  final DateTime createdAt;
}

/// Тема в составе конкретного плана (снимок на момент создания плана).
class PlanTopic {
  const PlanTopic({
    required this.topicId,
    required this.title,
    required this.category,
    required this.minutes,
    required this.level,
    required this.prerequisites,
    required this.position,
  });

  final String topicId;
  final String title;
  final String category;
  final int minutes;
  final int level;
  final List<String> prerequisites;
  final int position;

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
  const PlanProgress({
    required this.doneStudyMinutes,
    required this.totalStudyMinutes,
    required this.doneSessions,
    required this.totalSessions,
    required this.missedSessions,
    required this.finishDate,
  });

  final int doneStudyMinutes;
  final int totalStudyMinutes;
  final int doneSessions;
  final int totalSessions;
  final int missedSessions;
  final DateTime? finishDate;

  double get ratio =>
      totalStudyMinutes == 0 ? 0 : doneStudyMinutes / totalStudyMinutes;

  factory PlanProgress.fromSessions(
    List<StudySession> sessions,
    DateTime today,
  ) {
    var done = 0;
    var total = 0;
    var doneCount = 0;
    var missed = 0;
    DateTime? finish;
    for (final s in sessions) {
      if (s.kind == SessionKind.study) {
        total += s.minutes;
        if (s.isDone) done += s.minutes;
        if (finish == null || s.date.isAfter(finish)) finish = s.date;
      }
      if (s.isDone) doneCount++;
      if (s.isMissed(today)) missed++;
    }
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
