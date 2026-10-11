/// Заметка пользователя, при необходимости привязанная к теме.
class Note {
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

  final int id;
  final int userId;
  final String title;
  final String body;
  final String? topicId;
  final String? topicTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Завершённый интервал Pomodoro.
class PomodoroEntry {
  const PomodoroEntry({
    required this.id,
    required this.minutes,
    required this.completedAt,
    this.topicTitle,
  });

  final int id;
  final int minutes;
  final DateTime completedAt;
  final String? topicTitle;
}

/// Запись в истории активности.
class HistoryEntry {
  const HistoryEntry({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final DateTime at;
  final HistoryKind kind;
}

enum HistoryKind { session, review, pomodoro }
