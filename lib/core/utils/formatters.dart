// Файл formatters.dart — превращает даты, минуты и числа в текст для экрана.
// Слой: core (вспомогательные утилиты, без зависимостей от других слоёв).
// Используется почти всеми экранами presentation: план, темы, статистика,
// профиль, Помодоро и др. Даты форматируются пакетом intl на русском.
import 'package:intl/intl.dart';

/// Форматирование дат, длительностей и склонение слов на русском языке.
///
/// Все методы статические: объект класса создавать не нужно,
/// вызов выглядит как `Fmt.day(date)`.
abstract final class Fmt {
  /// Шаблон «число и месяц словом», например «5 марта».
  static final _day = DateFormat('d MMMM', 'ru');

  /// Шаблон «день недели, число и месяц», например «среда, 5 марта».
  static final _dayWeek = DateFormat('EEEE, d MMMM', 'ru');

  /// Короткая дата цифрами, например «05.03.2026».
  static final _short = DateFormat('dd.MM.yyyy', 'ru');

  /// Время в 24-часовом формате, например «14:30».
  static final _time = DateFormat('HH:mm', 'ru');

  /// Число, сокращённый месяц и время.
  static final _dateTime = DateFormat('d MMM, HH:mm', 'ru');

  /// Дата вида «5 марта».
  static String day(DateTime d) => _day.format(d);

  /// Дата с днём недели и заглавной буквой: «Среда, 5 марта».
  static String dayWithWeekday(DateTime d) => _capitalize(_dayWeek.format(d));

  /// Дата цифрами: «05.03.2026».
  static String short(DateTime d) => _short.format(d);

  /// Только время: «14:30».
  static String time(DateTime d) => _time.format(d);

  /// Дата с сокращённым месяцем и время.
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// 90 → «1 ч 30 мин», 45 → «45 мин», 120 → «2 ч».
  static String minutes(int minutes) {
    // Делим минуты на целые часы (~/ — деление без остатка) и остаток.
    final h = minutes ~/ 60;
    final m = minutes % 60;
    // Меньше часа — показываем только минуты.
    if (h == 0) return '$m мин';
    // Ровное число часов — показываем только часы.
    if (m == 0) return '$h ч';
    // Иначе и часы, и минуты.
    return '$h ч $m мин';
  }

  /// 7.5 → «7,5», 8.0 → «8».
  static String hours(num hours) {
    // Округляем до одного знака после запятой.
    final rounded = (hours * 10).round() / 10;
    // Целое число пишем без дробной части, дробное — как есть.
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    // В русском языке дробная часть отделяется запятой, а не точкой.
    return text.replaceAll('.', ',');
  }

  /// Слово «час» после числа часов: 1 час, 2,5 часа, 23,8 часа, 5 часов.
  /// Дробное число согласуется как «2–4» (родительный падеж единственного
  /// числа).
  static String hoursWord(num hours) {
    // Округляем так же, как в [hours], чтобы слово совпадало с числом.
    final rounded = (hours * 10).round() / 10;
    // Дробное число — всегда «часа».
    if (rounded != rounded.roundToDouble()) return 'часа';
    // Целое — склоняем по общим правилам.
    return plural(rounded.toInt(), 'час', 'часа', 'часов');
  }

  /// Склонение: plural(5, 'тема', 'темы', 'тем') → «тем».
  ///
  /// [one] — форма для 1, 21, 31…; [few] — для 2–4, 22–24…;
  /// [many] — для 0, 5–20, 25–30 и т. д.
  static String plural(int n, String one, String few, String many) {
    // Последняя цифра и две последние цифры числа.
    final mod10 = n % 10;
    final mod100 = n % 100;
    // Оканчивается на 1, но не на 11: «1 тема», «21 тема».
    if (mod10 == 1 && mod100 != 11) return one;
    // Оканчивается на 2–4, но не на 12–14: «3 темы», «24 темы».
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
    // Все остальные случаи: «5 тем», «12 тем».
    return many;
  }

  /// Число вместе с правильной формой слова: count(3, …) → «3 темы».
  static String count(int n, String one, String few, String many) =>
      '$n ${plural(n, one, few, many)}';

  /// Делает первую букву строки заглавной (пустую строку не трогает).
  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Короткие названия дней недели с понедельника по воскресенье.
///
/// В Dart понедельник — 1, воскресенье — 7, поэтому название дня `d`
/// берётся как `weekdayShort[d - 1]`.
const weekdayShort = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
