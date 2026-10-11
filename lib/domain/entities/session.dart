/// Тип занятия: изучение новой темы или интервальное повторение.
enum SessionKind {
  study,
  review;

  String get label => this == study ? 'Изучение' : 'Повторение';

  static SessionKind fromName(String name) =>
      SessionKind.values.firstWhere((k) => k.name == name, orElse: () => study);
}

/// Занятие, рассчитанное алгоритмом (ещё не сохранённое в базе).
class PlannedSession {
  const PlannedSession({
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.date,
    required this.minutes,
    required this.kind,
    this.part = 1,
    this.totalParts = 1,
  });

  final String topicId;
  final String topicTitle;
  final String category;

  /// Дата занятия (полночь по местному времени).
  final DateTime date;
  final int minutes;
  final SessionKind kind;

  /// Номер части темы и общее число частей (тема может занимать несколько дней).
  final int part;
  final int totalParts;

  PlannedSession copyWith({int? part, int? totalParts}) => PlannedSession(
    topicId: topicId,
    topicTitle: topicTitle,
    category: category,
    date: date,
    minutes: minutes,
    kind: kind,
    part: part ?? this.part,
    totalParts: totalParts ?? this.totalParts,
  );

  @override
  String toString() =>
      'PlannedSession($topicId, ${date.toIso8601String().substring(0, 10)}, '
      '$minutes мин, ${kind.name})';
}

/// Занятие, сохранённое в базе данных.
class StudySession {
  const StudySession({
    required this.id,
    required this.planId,
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.date,
    required this.minutes,
    required this.kind,
    required this.part,
    required this.totalParts,
    required this.isDone,
    this.completedAt,
  });

  final int id;
  final int planId;
  final String topicId;
  final String topicTitle;
  final String category;
  final DateTime date;
  final int minutes;
  final SessionKind kind;
  final int part;
  final int totalParts;
  final bool isDone;
  final DateTime? completedAt;

  /// Занятие пропущено: его дата раньше сегодняшней, а отметки нет.
  bool isMissed(DateTime today) => !isDone && date.isBefore(today);

  String get displayTitle => kind == SessionKind.review
      ? 'Повторение: $topicTitle'
      : totalParts > 1
      ? '$topicTitle (часть $part из $totalParts)'
      : topicTitle;
}
