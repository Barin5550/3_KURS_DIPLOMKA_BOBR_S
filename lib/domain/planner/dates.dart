/// Вспомогательные функции для работы с датами без учёта времени суток.
///
/// Дни прибавляются через конструктор `DateTime(y, m, d + n)`, а не через
/// `Duration(days: n)`, чтобы переход на летнее время не сдвигал даты.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Количество календарных дней от [from] до [to] (может быть отрицательным).
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Количество учебных дней в интервале [from; to] включительно.
int countStudyDays(DateTime from, DateTime to, Set<int> studyDays) {
  var count = 0;
  for (var d = dateOnly(from); !d.isAfter(to); d = addDays(d, 1)) {
    if (studyDays.contains(d.weekday)) count++;
  }
  return count;
}
