// Планировщик — раскладка тем по календарю (слой domain, папка planner).
// Берёт уже упорядоченные темы и расставляет занятия по учебным дням с
// дневным лимитом минут, добавляя интервальные повторения через 1, 3 и 7
// дней после изучения темы. Используется в PlanGenerator и Replanner.

import 'dart:collection';

import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';

/// Повторение, которое нужно провести не раньше [dueDate].
///
/// Это «заявка» на повторение: в расписание она превращается в занятие
/// типа «повторение», когда планировщик дойдёт до подходящего дня.
class PendingReview {
  /// Создаёт заявку на повторение темы; все поля обязательны.
  const PendingReview({
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.dueDate,
  });

  /// id темы, которую нужно повторить.
  final String topicId;

  /// Название темы (копируется в занятие-повторение).
  final String topicTitle;

  /// Категория темы (тоже копируется в занятие).
  final String category;

  /// Самая ранняя дата, на которую можно поставить повторение.
  final DateTime dueDate;
}

/// Раскладывает упорядоченные темы по учебным дням.
///
/// Алгоритм моделирует календарь день за днём, начиная с даты старта:
/// 1. Невыбранные дни недели пропускаются.
/// 2. В учебный день доступно [ScheduleSettings.dailyLimitMinutes] минут.
/// 3. Сначала в день ставятся повторения, срок которых наступил
///    (по [reviewMinutes] минут каждое).
/// 4. Оставшееся время заполняется текущей темой. Тема дробится на части,
///    но не мельче [minChunkMinutes], если остаток темы больше этого порога.
/// 5. Когда тема закончена, планируются повторения через [reviewIntervals]
///    календарных дней (по кривой забывания Эббингауза: 1, 3, 7 дней).
///    Повторение, выпавшее на неучебный день, переносится на ближайший учебный.
class Scheduler {
  /// Создаёт планировщик. По умолчанию: повторения через 1, 3 и 7 дней
  /// по 15 минут, части темы не короче 30 минут и не больше 3650 шагов
  /// по календарю (около 10 лет).
  const Scheduler({
    this.reviewIntervals = const [1, 3, 7],
    this.reviewMinutes = 15,
    this.minChunkMinutes = 30,
    this.maxDays = 3650,
  });

  /// Через сколько календарных дней после завершения темы ставить
  /// повторения (по умолчанию 1, 3 и 7 дней).
  final List<int> reviewIntervals;

  /// Длительность одного повторения в минутах.
  final int reviewMinutes;

  /// Минимальная длина части темы в минутах, чтобы тема не дробилась
  /// на совсем короткие кусочки.
  final int minChunkMinutes;

  /// Защита от бесконечного цикла при некорректных настройках.
  final int maxDays;

  /// [remainingMinutes] позволяет передать остаток по теме, если часть уже
  /// изучена (используется при перепланировании). По умолчанию —
  /// полная длительность темы.
  /// [initialReviews] — повторения, перенесённые из прошлого расписания.
  ///
  /// Возвращает список занятий [PlannedSession] в порядке дат. Бросает
  /// [ArgumentError], если не выбран ни один учебный день.
  List<PlannedSession> schedule(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
    List<PendingReview> initialReviews = const [],
  }) {
    // Сколько минут можно заниматься в один учебный день.
    final dailyLimit = settings.dailyLimitMinutes;
    // Без учебных дней (или с нулевым лимитом) план построить нельзя.
    if (settings.studyDays.isEmpty || dailyLimit <= 0) {
      throw ArgumentError('Нужно выбрать хотя бы один учебный день');
    }

    // Очередь (Queue — список «первым пришёл — первым ушёл») тем, которые
    // ещё нужно изучить, в порядке сортировки. Для каждой темы храним
    // остаток минут: полный или из remainingMinutes. Темы с нулевым
    // остатком сразу отбрасываем — они уже изучены.
    final work = Queue<_TopicWork>()
      ..addAll(
        orderedTopics
            .map((t) => _TopicWork(t, remainingMinutes[t.id] ?? t.minutes))
            .where((w) => w.remaining > 0),
      );
    // Ожидающие повторения, отсортированные по сроку (ближайшие первыми).
    final reviews = [...initialReviews]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    // Сюда складываем готовые занятия.
    final sessions = <PlannedSession>[];

    // Идём по календарю день за днём, начиная с даты старта. maxDays
    // ограничивает число шагов, чтобы цикл точно закончился.
    var day = dateOnly(settings.startDate);
    for (var i = 0; i < maxDays; i++, day = addDays(day, 1)) {
      // Темы и повторения закончились — расписание готово.
      if (work.isEmpty && reviews.isEmpty) break;
      // Шаг 1: день недели не выбран как учебный — пропускаем его.
      if (!settings.studyDays.contains(day.weekday)) continue;

      // Шаг 2: свободное время на сегодня равно дневному лимиту.
      var capacity = dailyLimit;

      // Шаг 3: повторения, срок которых наступил.
      // Берём повторения со сроком сегодня или раньше. Сюда же попадают
      // повторения, выпавшие на неучебный день, — так они переносятся
      // на ближайший учебный день.
      final due = reviews.where((r) => !r.dueDate.isAfter(day)).toList();
      for (final review in due) {
        // Время на ещё одно повторение закончилось — остальные
        // повторения перейдут на следующий учебный день.
        if (capacity < reviewMinutes) break;
        // Ставим занятие-повторение на сегодня.
        sessions.add(
          PlannedSession(
            topicId: review.topicId,
            topicTitle: review.topicTitle,
            category: review.category,
            date: day,
            minutes: reviewMinutes,
            kind: SessionKind.review,
          ),
        );
        // Уменьшаем свободное время и убираем повторение из ожидающих.
        capacity -= reviewMinutes;
        reviews.remove(review);
      }

      // Шаг 4: новые темы.
      // Пока есть темы и свободное время, заполняем день текущей темой.
      while (work.isNotEmpty && capacity > 0) {
        // Текущая тема — первая в очереди.
        final current = work.first;
        // Размер части: сколько поместится сегодня, но не больше, чем
        // осталось изучить по теме.
        final chunk = capacity < current.remaining
            ? capacity
            : current.remaining;
        // Кусок короче минимума и это не конец темы — не дробим тему
        // мелко, а переносим её продолжение на следующий учебный день.
        if (chunk < minChunkMinutes && chunk < current.remaining) break;

        // Ставим занятие «изучение» на сегодня.
        sessions.add(
          PlannedSession(
            topicId: current.topic.id,
            topicTitle: current.topic.title,
            category: current.topic.category,
            date: day,
            minutes: chunk,
            kind: SessionKind.study,
          ),
        );
        // Уменьшаем свободное время дня и остаток темы.
        capacity -= chunk;
        current.remaining -= chunk;

        // Тема изучена полностью.
        if (current.remaining == 0) {
          // Убираем её из очереди — дальше пойдёт следующая тема.
          work.removeFirst();
          // Шаг 5: повторения после завершения темы.
          // Для каждого интервала (1, 3, 7 дней) создаём заявку на
          // повторение со сроком «день завершения + интервал».
          for (final interval in reviewIntervals) {
            reviews.add(
              PendingReview(
                topicId: current.topic.id,
                topicTitle: current.topic.title,
                category: current.topic.category,
                dueDate: addDays(day, interval),
              ),
            );
          }
          // Снова сортируем повторения по сроку, чтобы ближайшие
          // оставались в начале списка.
          reviews.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        }
      }
    }

    // Проставляем номера частей («часть 2 из 3») и отдаём результат.
    return _numberParts(sessions);
  }

  /// Проставляет номер части для тем, разбитых на несколько занятий.
  List<PlannedSession> _numberParts(List<PlannedSession> sessions) {
    // Сначала считаем, на сколько занятий разбита каждая тема.
    final totals = <String, int>{};
    for (final s in sessions) {
      if (s.kind == SessionKind.study) {
        totals[s.topicId] = (totals[s.topicId] ?? 0) + 1;
      }
    }
    // Счётчики уже пронумерованных частей по каждой теме.
    final counters = <String, int>{};
    // Проходим занятия по порядку: у занятия «изучение» увеличиваем
    // счётчик его темы и записываем «номер части / всего частей»;
    // повторения оставляем без изменений.
    return [
      for (final s in sessions)
        if (s.kind == SessionKind.study)
          s.copyWith(
            part: counters[s.topicId] = (counters[s.topicId] ?? 0) + 1,
            totalParts: totals[s.topicId],
          )
        else
          s,
    ];
  }
}

/// Служебная запись планировщика: тема и сколько минут по ней ещё осталось
/// распланировать. Поле [remaining] уменьшается по ходу раскладки.
/// Класс приватный (имя начинается с «_»), виден только в этом файле.
class _TopicWork {
  /// Создаёт запись для темы [topic] с остатком [remaining] минут.
  _TopicWork(this.topic, this.remaining);

  /// Тема, которую нужно разложить по дням.
  final Topic topic;

  /// Сколько минут темы ещё не поставлено в расписание.
  int remaining;
}
