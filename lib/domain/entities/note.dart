// Файл note.dart — сущности заметок, интервалов Pomodoro и истории.
// Слой: domain. Note и PomodoroEntry создаёт NoteRepositoryImpl (data)
// из строк базы данных; HistoryEntry собирается на экране статистики
// (presentation/screens/stats) из занятий и интервалов Pomodoro.
/// Заметка пользователя, при необходимости привязанная к теме.
class Note {
  /// Создаёт заметку; тема ([topicId], [topicTitle]) необязательна.
  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.topicId,
    this.topicTitle,
  });

  /// Номер заметки в базе данных.
  final int id;

  /// Владелец заметки (id пользователя).
  final int userId;

  /// Заголовок заметки.
  final String title;

  /// Текст заметки.
  final String body;

  /// id темы, к которой привязана заметка (`null` — без темы).
  final String? topicId;

  /// Название этой темы (сохраняется вместе с заметкой).
  final String? topicTitle;

  /// Когда заметка создана.
  final DateTime createdAt;

  /// Когда заметку последний раз изменяли.
  final DateTime updatedAt;
}

/// Завершённый интервал Pomodoro.
///
/// Pomodoro — техника концентрации: работа короткими отрезками
/// с перерывами между ними.
class PomodoroEntry {
  /// Создаёт запись о завершённом интервале.
  const PomodoroEntry({
    required this.id,
    required this.minutes,
    required this.completedAt,
    this.topicTitle,
  });

  /// Номер записи в базе данных.
  final int id;

  /// Длительность интервала в минутах.
  final int minutes;

  /// Когда интервал завершён.
  final DateTime completedAt;

  /// Название темы, над которой работали (`null` — без темы).
  final String? topicTitle;
}

/// Запись в истории активности.
class HistoryEntry {
  /// Создаёт запись истории.
  const HistoryEntry({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.kind,
  });

  /// Главная строка записи (например, название занятия).
  final String title;

  /// Вторая строка (например, длительность).
  final String subtitle;

  /// Когда это произошло.
  final DateTime at;

  /// Вид записи — по нему на экране статистики выбирается иконка.
  final HistoryKind kind;
}

/// Вид записи в истории: изучение темы, повторение или интервал Pomodoro.
enum HistoryKind { session, review, pomodoro }
