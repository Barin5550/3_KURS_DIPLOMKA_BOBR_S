// Файл schedule_settings.dart — настройки расписания учёбы.
// Слой: domain. Пользователь задаёт их на шаге онбординга «Расписание»
// и в настройках плана; по ним алгоритм планировщика (domain/planner)
// раскладывает темы по дням. Сохраняются вместе с планом (StudyPlan).
/// Параметры расписания, которые указывает пользователь.
class ScheduleSettings {
  /// Создаёт настройки; [deadline] необязателен.
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
  ///
  /// Недельные часы делятся поровну между учебными днями; результат
  /// округляется до 15 минут, но не бывает меньше 30 минут.
  int get dailyLimitMinutes {
    // Нет учебных дней — заниматься некогда.
    if (studyDays.isEmpty) return 0;
    // Минуты в неделю, делённые на число учебных дней.
    final raw = hoursPerWeek * 60 / studyDays.length;
    // Округляем до ближайшего числа, кратного 15.
    final rounded = (raw / 15).round() * 15;
    // Минимум — 30 минут в день.
    return rounded < 30 ? 30 : rounded;
  }

  /// Возвращает копию настроек с заменой указанных полей.
  ///
  /// Чтобы убрать дедлайн, передайте `clearDeadline: true` (просто `null`
  /// в [deadline] означает «оставить как было»).
  ScheduleSettings copyWith({
    double? hoursPerWeek,
    Set<int>? studyDays,
    DateTime? startDate,
    DateTime? deadline,
    bool clearDeadline = false,
  }) => ScheduleSettings(
    // Для каждого поля: новое значение, если передано, иначе старое.
    hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
    studyDays: studyDays ?? this.studyDays,
    startDate: startDate ?? this.startDate,
    // Дедлайн можно явно очистить флагом clearDeadline.
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
  );
}
