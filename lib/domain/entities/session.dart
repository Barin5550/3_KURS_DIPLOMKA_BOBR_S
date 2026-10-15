// Файл session.dart — сущности учебного занятия.
// Слой: domain. PlannedSession создаёт планировщик (domain/planner) при
// расчёте плана; PlanRepositoryImpl (data) сохраняет его в базу и
// возвращает уже как StudySession. StudySession показывают главная,
// план, экран занятия, статистика и виджет SessionTile (presentation).
/// Тип занятия: изучение новой темы или интервальное повторение.
///
/// Интервальное повторение — возврат к пройденной теме через несколько
/// дней, чтобы лучше её запомнить.
enum SessionKind {
  /// Изучение новой темы.
  study,

  /// Повторение уже изученной темы.
  review;

  /// Подпись типа занятия для интерфейса.
  String get label => this == study ? 'Изучение' : 'Повторение';

  /// Находит тип по имени (`'study'` / `'review'`), сохранённому в базе;
  /// неизвестное имя считается изучением.
  static SessionKind fromName(String name) =>
      SessionKind.values.firstWhere((k) => k.name == name, orElse: () => study);
}

/// Занятие, рассчитанное алгоритмом (ещё не сохранённое в базе).
class PlannedSession {
  /// Создаёт запланированное занятие; по умолчанию тема в одной части.
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

  /// id темы занятия.
  final String topicId;

  /// Название темы для отображения.
  final String topicTitle;

  /// Категория темы.
  final String category;

  /// Дата занятия (полночь по местному времени).
  final DateTime date;

  /// Длительность занятия в минутах.
  final int minutes;

  /// Тип занятия: изучение или повторение.
  final SessionKind kind;

  /// Номер части темы и общее число частей (тема может занимать
  /// несколько дней).
  final int part;

  /// Общее число частей, на которые разбита тема.
  final int totalParts;

  /// Копия занятия с другими номером части и/или числом частей.
  PlannedSession copyWith({int? part, int? totalParts}) => PlannedSession(
    // Все поля, кроме частей, переносим без изменений.
    topicId: topicId,
    topicTitle: topicTitle,
    category: category,
    date: date,
    minutes: minutes,
    kind: kind,
    // Новые значения частей, если переданы, иначе старые.
    part: part ?? this.part,
    totalParts: totalParts ?? this.totalParts,
  );

  /// Текст для отладки: тема, дата (ГГГГ-ММ-ДД), минуты и тип.
  @override
  String toString() =>
      'PlannedSession($topicId, ${date.toIso8601String().substring(0, 10)}, '
      '$minutes мин, ${kind.name})';
}

/// Занятие, сохранённое в базе данных.
class StudySession {
  /// Создаёт занятие со всеми полями из базы.
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

  /// Номер занятия в базе данных.
  final int id;

  /// План, к которому относится занятие.
  final int planId;

  /// id темы занятия.
  final String topicId;

  /// Название темы.
  final String topicTitle;

  /// Категория темы.
  final String category;

  /// Дата занятия.
  final DateTime date;

  /// Длительность в минутах.
  final int minutes;

  /// Тип занятия: изучение или повторение.
  final SessionKind kind;

  /// Номер части темы.
  final int part;

  /// Общее число частей темы.
  final int totalParts;

  /// Отмечено ли занятие как выполненное.
  final bool isDone;

  /// Когда занятие отметили выполненным (`null` — ещё не выполнено).
  final DateTime? completedAt;

  /// Занятие пропущено: его дата раньше сегодняшней, а отметки нет.
  bool isMissed(DateTime today) => !isDone && date.isBefore(today);

  /// Заголовок для списка: «Повторение: Тема», «Тема (часть 2 из 3)»
  /// или просто название темы.
  String get displayTitle => kind == SessionKind.review
      ? 'Повторение: $topicTitle'
      : totalParts > 1
      ? '$topicTitle (часть $part из $totalParts)'
      : topicTitle;
}
