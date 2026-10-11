/// Параметры расписания, которые указывает пользователь.
class ScheduleSettings {
  const ScheduleSettings({
    required this.hoursPerWeek,
    required this.studyDays,
    required this.startDate,
    this.deadline,
  });

  /// Сколько часов в неделю пользователь готов учиться.
  final double hoursPerWeek;

  /// Учебные дни недели: [DateTime.monday] (1) … [DateTime.sunday] (7).
  final Set<int> studyDays;

  /// Дата начала обучения (время суток не учитывается).
  final DateTime startDate;

  /// Желаемая дата окончания. `null` — без дедлайна.
  final DateTime? deadline;

  /// Лимит минут в один учебный день, кратный 15 минутам.
  int get dailyLimitMinutes {
    if (studyDays.isEmpty) return 0;
    final raw = hoursPerWeek * 60 / studyDays.length;
    final rounded = (raw / 15).round() * 15;
    return rounded < 30 ? 30 : rounded;
  }

  ScheduleSettings copyWith({
    double? hoursPerWeek,
    Set<int>? studyDays,
    DateTime? startDate,
    DateTime? deadline,
    bool clearDeadline = false,
  }) => ScheduleSettings(
    hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
    studyDays: studyDays ?? this.studyDays,
    startDate: startDate ?? this.startDate,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
  );
}
