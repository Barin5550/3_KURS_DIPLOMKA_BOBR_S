// Вспомогательные функции для работы с датами (слой domain, папка planner).
// Классов здесь нет — только маленькие функции верхнего уровня. Их используют
// планировщик (Scheduler, Replanner), PlanService, провайдеры и экраны
// (главный, план, статистика, Pomodoro), чтобы сравнивать и сдвигать даты
// без учёта часов и минут.

/// Вспомогательные функции для работы с датами без учёта времени суток.
///
/// Дни прибавляются через конструктор `DateTime(y, m, d + n)`, а не через
/// `Duration(days: n)`, чтобы переход на летнее время не сдвигал даты.
///
/// Сама функция [dateOnly] отбрасывает часы, минуты и секунды: возвращает
/// ту же календарную дату, но на полночь (00:00) по местному времени.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Возвращает дату, сдвинутую на [days] календарных дней (при отрицательном
/// [days] — назад). Если день «вылезает» за конец месяца (например, 32
/// января), `DateTime` сам переносит его в следующий месяц.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Количество календарных дней от [from] до [to] (может быть отрицательным).
///
/// Обе даты переводятся в UTC без времени суток: в UTC нет перехода на
/// летнее время, поэтому разница всегда равна целому числу суток.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Проверяет, приходятся ли [a] и [b] на один календарный день
/// (сравниваются только год, месяц и число, время суток не важно).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Количество учебных дней в интервале [from; to] включительно.
///
/// [studyDays] — номера дней недели, в которые пользователь занимается
/// (1 — понедельник … 7 — воскресенье, как в `DateTime.weekday`).
int countStudyDays(DateTime from, DateTime to, Set<int> studyDays) {
  // Счётчик найденных учебных дней.
  var count = 0;
  // Перебираем все дни от from до to включительно с шагом в один день.
  for (var d = dateOnly(from); !d.isAfter(to); d = addDays(d, 1)) {
    // Если день недели входит в выбранные учебные дни — считаем его.
    if (studyDays.contains(d.weekday)) count++;
  }
  // Возвращаем, сколько учебных дней набралось.
  return count;
}
