import 'package:intl/intl.dart';

/// Форматирование дат, длительностей и склонение слов на русском языке.
abstract final class Fmt {
  static final _day = DateFormat('d MMMM', 'ru');
  static final _dayWeek = DateFormat('EEEE, d MMMM', 'ru');
  static final _short = DateFormat('dd.MM.yyyy', 'ru');
  static final _time = DateFormat('HH:mm', 'ru');
  static final _dateTime = DateFormat('d MMM, HH:mm', 'ru');

  static String day(DateTime d) => _day.format(d);
  static String dayWithWeekday(DateTime d) => _capitalize(_dayWeek.format(d));
  static String short(DateTime d) => _short.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// 90 → «1 ч 30 мин», 45 → «45 мин», 120 → «2 ч».
  static String minutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m мин';
    if (m == 0) return '$h ч';
    return '$h ч $m мин';
  }

  /// 7.5 → «7,5», 8.0 → «8».
  static String hours(num hours) {
    final rounded = (hours * 10).round() / 10;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    return text.replaceAll('.', ',');
  }

  /// Слово «час» после числа часов: 1 час, 2,5 часа, 23,8 часа, 5 часов.
  /// Дробное число согласуется как «2–4» (родительный падеж единственного
  /// числа).
  static String hoursWord(num hours) {
    final rounded = (hours * 10).round() / 10;
    if (rounded != rounded.roundToDouble()) return 'часа';
    return plural(rounded.toInt(), 'час', 'часа', 'часов');
  }

  /// Склонение: plural(5, 'тема', 'темы', 'тем') → «тем».
  static String plural(int n, String one, String few, String many) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return one;
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    return many;
  }

  static String count(int n, String one, String few, String many) =>
      '$n ${plural(n, one, few, many)}';

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

const weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
