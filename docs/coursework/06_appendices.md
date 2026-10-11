<!-- Файл создан tool/coursework/build_coursework.py из исходного кода. Не редактируйте вручную. -->

# ПРИЛОЖЕНИЕ А. ТОПОЛОГИЧЕСКАЯ СОРТИРОВКА ТЕМ (АЛГОРИТМ КАНА)

Файл `lib/domain/planner/topological_sort.dart`.

```dart
import 'dart:collection';

import '../entities/topic.dart';

/// В графе тем обнаружен цикл, поэтому порядок изучения построить нельзя.
class CycleDetectedException implements Exception {
  CycleDetectedException(this.topicIds);

  /// Темы, которые остались неупорядоченными (входят в цикл или зависят от него).
  final List<String> topicIds;

  @override
  String toString() => 'В зависимостях тем есть цикл: ${topicIds.join(', ')}';
}

/// Топологическая сортировка тем алгоритмом Кана.
///
/// 1. Для каждой темы считаем входящую степень — число её зависимостей
///    внутри переданного набора. Зависимости, которых нет в наборе
///    (например, уже изученные темы), считаются выполненными.
/// 2. Темы с нулевой степенью помещаем в очередь с приоритетом.
/// 3. Извлекаем тему, добавляем в результат и уменьшаем степень у всех тем,
///    которые от неё зависят. Если степень стала нулевой — тема в очередь.
/// 4. Если в результат попали не все темы, в графе есть цикл.
///
/// Очередь упорядочена по уровню сложности, затем по исходной позиции темы,
/// поэтому при одинаковых входных данных результат всегда одинаковый.
/// Сложность — O((V + E) · log V) из-за очереди с приоритетом.
List<Topic> topologicalSort(List<Topic> topics) {
  final index = <String, int>{
    for (var i = 0; i < topics.length; i++) topics[i].id: i,
  };
  final inDegree = List<int>.filled(topics.length, 0);
  final dependents = List.generate(topics.length, (_) => <int>[]);

  for (var i = 0; i < topics.length; i++) {
    for (final prerequisite in topics[i].prerequisites.toSet()) {
      final from = index[prerequisite];
      if (from == null) continue; // зависимость уже изучена или вне плана
      dependents[from].add(i);
      inDegree[i]++;
    }
  }

  int compare(int a, int b) {
    final byLevel = topics[a].level.compareTo(topics[b].level);
    return byLevel != 0 ? byLevel : a.compareTo(b);
  }

  final queue = SplayTreeSet<int>(compare);
  for (var i = 0; i < topics.length; i++) {
    if (inDegree[i] == 0) queue.add(i);
  }

  final result = <Topic>[];
  while (queue.isNotEmpty) {
    final current = queue.first;
    queue.remove(current);
    result.add(topics[current]);
    for (final next in dependents[current]) {
      inDegree[next]--;
      if (inDegree[next] == 0) queue.add(next);
    }
  }

  if (result.length != topics.length) {
    final sorted = result.map((t) => t.id).toSet();
    throw CycleDetectedException(
      topics.where((t) => !sorted.contains(t.id)).map((t) => t.id).toList(),
    );
  }
  return result;
}
```

# ПРИЛОЖЕНИЕ Б. ХЭШИРОВАНИЕ ПАРОЛЕЙ PBKDF2-HMAC-SHA256

Файл `lib/core/utils/password_hasher.dart`.

```dart
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;

/// Хэширование паролей алгоритмом PBKDF2-HMAC-SHA256 (RFC 8018).
///
/// Соль — 16 случайных байт из криптостойкого генератора [Random.secure].
/// Благодаря соли одинаковые пароли разных пользователей дают разные хэши,
/// а готовые таблицы хэшей («радужные таблицы») бесполезны. Многократное
/// повторение HMAC ([iterations] раз) замедляет подбор пароля перебором:
/// так рекомендует OWASP вместо однократного SHA-256.
///
/// Хэш хранится в виде `pbkdf2_sha256$<итерации>$<hex>`, поэтому число
/// итераций можно увеличить позже, не ломая старые записи. Хэши версии
/// 1 семестра (однократный SHA-256 от «соль + пароль») по-прежнему
/// проверяются и заменяются новыми при входе (см. [needsRehash]).
class PasswordHasher {
  PasswordHasher({Random? random, this.iterations = defaultIterations})
    : assert(iterations > 0),
      _random = random ?? Random.secure();

  /// Число итераций по умолчанию: заметно замедляет перебор и при этом
  /// не задерживает вход на телефоне дольше долей секунды.
  static const defaultIterations = 100000;

  static const _scheme = 'pbkdf2_sha256';

  final int iterations;
  final Random _random;

  String generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Хэш пароля в текущем формате.
  String hash(String password, String salt) => _format(
    iterations,
    pbkdf2(utf8.encode(password), utf8.encode(salt), iterations),
  );

  /// [hash] в фоновом изоляте, чтобы интерфейс не замирал на время расчёта.
  Future<String> hashAsync(String password, String salt) {
    if (iterations < _isolateThreshold) {
      return Future.value(hash(password, salt));
    }
    final rounds = iterations;
    return compute(
      (_) => PasswordHasher(iterations: rounds).hash(password, salt),
      null,
    );
  }

  /// [verify] в фоновом изоляте.
  Future<bool> verifyAsync(String password, String salt, String stored) {
    final rounds = _iterationsOf(stored) ?? 1;
    if (rounds < _isolateThreshold) {
      return Future.value(verify(password, salt, stored));
    }
    return compute(
      (_) => PasswordHasher(iterations: 1).verify(password, salt, stored),
      null,
    );
  }

  /// При малом числе итераций запуск изолята дороже самого вычисления.
  static const _isolateThreshold = 10000;

  /// Хэш старого формата (версия 1 семестра): SHA-256 от «соль + пароль».
  static String legacyHash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  bool verify(String password, String salt, String stored) {
    final String actual;
    final rounds = _iterationsOf(stored);
    if (rounds != null) {
      actual = _format(
        rounds,
        pbkdf2(utf8.encode(password), utf8.encode(salt), rounds),
      );
    } else {
      actual = legacyHash(password, salt);
    }
    return _constantTimeEquals(actual, stored);
  }

  /// `true`, если хэш старого формата или посчитан с меньшим числом итераций.
  bool needsRehash(String stored) {
    final rounds = _iterationsOf(stored);
    return rounds == null || rounds < iterations;
  }

  /// PBKDF2 с HMAC-SHA256. Для ключа длиной до 32 байт нужен один блок:
  /// T = U1 ⊕ U2 ⊕ … ⊕ Uc, где U1 = HMAC(P, S ‖ 00000001), Uj = HMAC(P, Uj-1).
  static List<int> pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations, [
    int length = 32,
  ]) {
    final prf = Hmac(sha256, password);
    final blocks = (length + 31) ~/ 32;
    final result = <int>[];
    for (var block = 1; block <= blocks; block++) {
      var u = prf.convert([
        ...salt,
        block >> 24 & 0xff,
        block >> 16 & 0xff,
        block >> 8 & 0xff,
        block & 0xff,
      ]).bytes;
      final t = List<int>.of(u);
      for (var i = 1; i < iterations; i++) {
        u = prf.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.addAll(t);
    }
    return result.sublist(0, length);
  }

  static String _format(int rounds, List<int> key) =>
      '$_scheme\$$rounds\$${_hex(key)}';

  static int? _iterationsOf(String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 3 || parts[0] != _scheme) return null;
    final rounds = int.tryParse(parts[1]);
    return rounds != null && rounds > 0 ? rounds : null;
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Сравнение без раннего выхода, чтобы время не зависело от совпадения.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
```

# ПРИЛОЖЕНИЕ В. РАСКЛАДКА ТЕМ ПО ДНЯМ И ИНТЕРВАЛЬНЫЕ ПОВТОРЕНИЯ

Файл `lib/domain/planner/scheduler.dart`.

```dart
import 'dart:collection';

import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';

/// Повторение, которое нужно провести не раньше [dueDate].
class PendingReview {
  const PendingReview({
    required this.topicId,
    required this.topicTitle,
    required this.category,
    required this.dueDate,
  });

  final String topicId;
  final String topicTitle;
  final String category;
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
  const Scheduler({
    this.reviewIntervals = const [1, 3, 7],
    this.reviewMinutes = 15,
    this.minChunkMinutes = 30,
    this.maxDays = 3650,
  });

  final List<int> reviewIntervals;
  final int reviewMinutes;
  final int minChunkMinutes;

  /// Защита от бесконечного цикла при некорректных настройках.
  final int maxDays;

  /// [remainingMinutes] позволяет передать остаток по теме, если часть уже
  /// изучена (используется при перепланировании). По умолчанию —
  /// полная длительность темы.
  /// [initialReviews] — повторения, перенесённые из прошлого расписания.
  List<PlannedSession> schedule(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
    List<PendingReview> initialReviews = const [],
  }) {
    final dailyLimit = settings.dailyLimitMinutes;
    if (settings.studyDays.isEmpty || dailyLimit <= 0) {
      throw ArgumentError('Нужно выбрать хотя бы один учебный день');
    }

    final work = Queue<_TopicWork>()
      ..addAll(
        orderedTopics
            .map((t) => _TopicWork(t, remainingMinutes[t.id] ?? t.minutes))
            .where((w) => w.remaining > 0),
      );
    final reviews = [...initialReviews]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final sessions = <PlannedSession>[];

    var day = dateOnly(settings.startDate);
    for (var i = 0; i < maxDays; i++, day = addDays(day, 1)) {
      if (work.isEmpty && reviews.isEmpty) break;
      if (!settings.studyDays.contains(day.weekday)) continue;

      var capacity = dailyLimit;

      // Шаг 3: повторения, срок которых наступил.
      final due = reviews.where((r) => !r.dueDate.isAfter(day)).toList();
      for (final review in due) {
        if (capacity < reviewMinutes) break;
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
        capacity -= reviewMinutes;
        reviews.remove(review);
      }

      // Шаг 4: новые темы.
      while (work.isNotEmpty && capacity > 0) {
        final current = work.first;
        final chunk = capacity < current.remaining
            ? capacity
            : current.remaining;
        if (chunk < minChunkMinutes && chunk < current.remaining) break;

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
        capacity -= chunk;
        current.remaining -= chunk;

        if (current.remaining == 0) {
          work.removeFirst();
          // Шаг 5: повторения после завершения темы.
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
          reviews.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        }
      }
    }

    return _numberParts(sessions);
  }

  /// Проставляет номер части для тем, разбитых на несколько занятий.
  List<PlannedSession> _numberParts(List<PlannedSession> sessions) {
    final totals = <String, int>{};
    for (final s in sessions) {
      if (s.kind == SessionKind.study) {
        totals[s.topicId] = (totals[s.topicId] ?? 0) + 1;
      }
    }
    final counters = <String, int>{};
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

class _TopicWork {
  _TopicWork(this.topic, this.remaining);

  final Topic topic;
  int remaining;
}
```

# ПРИЛОЖЕНИЕ Г. ГЕНЕРАТОР ПЛАНА И ПРОВЕРКА ДЕДЛАЙНА

Файл `lib/domain/planner/plan_generator.dart`.

```dart
import '../entities/plan.dart';
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'scheduler.dart';
import 'topological_sort.dart';

/// Генератор персонального плана обучения.
///
/// Конвейер из пяти шагов:
/// 1. Направление — граф тем с зависимостями (вход [topics]).
/// 2. Темы, известные по результатам теста ([knownTopicIds]), исключаются.
/// 3. Оставшиеся темы упорядочиваются топологической сортировкой (Кан).
/// 4. Темы раскладываются по учебным дням с лимитом часов ([Scheduler]).
/// 5. Проверяется дедлайн; если он не выполняется, подбирается минимальное
///    число часов в неделю, при котором план в него укладывается.
///    Интервальные повторения добавляет [Scheduler] на шаге 4.
class PlanGenerator {
  const PlanGenerator({this.scheduler = const Scheduler()});

  final Scheduler scheduler;

  /// Максимум часов в неделю, который имеет смысл предлагать (12 ч × 7 дней).
  static const double maxHoursPerWeek = 84;

  PlanResult generate({
    required List<Topic> topics,
    required ScheduleSettings settings,
    Set<String> knownTopicIds = const {},
  }) {
    // Шаг 2.
    final excluded = topics.where((t) => knownTopicIds.contains(t.id)).toList();
    final remaining = topics
        .where((t) => !knownTopicIds.contains(t.id))
        .toList();

    // Шаг 3.
    final ordered = topologicalSort(remaining);

    // Шаг 4.
    final sessions = scheduler.schedule(ordered, settings);
    final finish = lastStudyDate(sessions);

    // Шаг 5.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);

    return PlanResult(
      orderedTopics: ordered,
      excludedTopics: excluded,
      sessions: sessions,
      finishDate: finish,
      deadlineMet: met,
      requiredHoursPerWeek: met
          ? null
          : requiredHoursPerWeek(ordered, settings),
    );
  }

  /// Подбирает минимальное число часов в неделю (с шагом 0,5 ч), при котором
  /// все темы будут изучены не позже дедлайна. Возвращает `null`, если даже
  /// [maxHoursPerWeek] не хватает.
  double? requiredHoursPerWeek(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
  }) {
    final deadline = settings.deadline;
    if (deadline == null) return null;

    for (
      var hours = settings.hoursPerWeek + 0.5;
      hours <= maxHoursPerWeek;
      hours += 0.5
    ) {
      final candidate = settings.copyWith(hoursPerWeek: hours);
      final sessions = scheduler.schedule(
        orderedTopics,
        candidate,
        remainingMinutes: remainingMinutes,
      );
      final finish = lastStudyDate(sessions);
      if (finish == null || !finish.isAfter(deadline)) return hours;
    }
    return null;
  }

  static DateTime? lastStudyDate(List<PlannedSession> sessions) {
    DateTime? last;
    for (final s in sessions) {
      if (s.kind != SessionKind.study) continue;
      if (last == null || s.date.isAfter(last)) last = s.date;
    }
    return last;
  }
}
```

# ПРИЛОЖЕНИЕ Д. ПЕРЕПЛАНИРОВАНИЕ

Файл `lib/domain/planner/replanner.dart`.

```dart
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';
import 'plan_generator.dart';
import 'scheduler.dart';

/// Результат перепланирования.
class ReplanResult {
  const ReplanResult({
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Новые невыполненные занятия, начиная с сегодняшнего дня.
  final List<PlannedSession> sessions;
  final DateTime? finishDate;
  final bool deadlineMet;
  final double? requiredHoursPerWeek;
}

/// Перестраивает план, если пользователь отстал или изменил расписание.
///
/// Выполненные занятия остаются на своих местах. Для каждой темы считается,
/// сколько минут уже изучено; остаток заново раскладывается начиная с
/// [today] теми же правилами, что и при генерации. Невыполненные повторения
/// по уже изученным темам переносятся на ближайшие учебные дни.
class Replanner {
  const Replanner({this.scheduler = const Scheduler()});

  final Scheduler scheduler;

  ReplanResult replan({
    required List<Topic> orderedTopics,
    required List<StudySession> sessions,
    required ScheduleSettings settings,
    required DateTime today,
  }) {
    final start = dateOnly(today);

    final doneMinutes = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneMinutes[s.topicId] = (doneMinutes[s.topicId] ?? 0) + s.minutes;
      }
    }

    final remaining = <String, int>{
      for (final t in orderedTopics)
        t.id: (t.minutes - (doneMinutes[t.id] ?? 0)).clamp(0, t.minutes),
    };

    // Невыполненные повторения тем, которые уже изучены полностью.
    final pendingReviews = <PendingReview>[
      for (final s in sessions)
        if (!s.isDone &&
            s.kind == SessionKind.review &&
            remaining[s.topicId] == 0)
          PendingReview(
            topicId: s.topicId,
            topicTitle: s.topicTitle,
            category: s.category,
            dueDate: s.date.isBefore(start) ? start : s.date,
          ),
    ];

    final newSettings = settings.copyWith(startDate: start);
    final planned = scheduler.schedule(
      orderedTopics,
      newSettings,
      remainingMinutes: remaining,
      initialReviews: pendingReviews,
    );

    // Номера частей продолжают уже выполненные части темы.
    final doneParts = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneParts[s.topicId] = (doneParts[s.topicId] ?? 0) + 1;
      }
    }
    final renumbered = [
      for (final s in planned)
        if (s.kind == SessionKind.study && (doneParts[s.topicId] ?? 0) > 0)
          s.copyWith(
            part: s.part + doneParts[s.topicId]!,
            totalParts: s.totalParts + doneParts[s.topicId]!,
          )
        else
          s,
    ];

    final finish = PlanGenerator.lastStudyDate(renumbered);
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);
    return ReplanResult(
      sessions: renumbered,
      finishDate: finish,
      deadlineMet: met,
      requiredHoursPerWeek: met
          ? null
          : PlanGenerator(scheduler: scheduler).requiredHoursPerWeek(
              orderedTopics,
              newSettings,
              remainingMinutes: remaining,
            ),
    );
  }
}
```

# ПРИЛОЖЕНИЕ Е. ТАБЛИЦЫ БАЗЫ ДАННЫХ

Файл `lib/data/db/app_database.dart`.

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

// Таблицы базы данных SQLite. Код запросов генерирует drift:
//   dart run build_runner build
// Сгенерированный файл app_database.g.dart хранится в репозитории, поэтому
// для запуска приложения генерация не нужна.

/// Пользователи. Пароль хранится только в виде хэша PBKDF2-HMAC-SHA256 с солью
/// (записи версии 1 семестра с хэшем SHA-256 пересчитываются при входе).
@DataClassName('UserRow')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 40)();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  IntColumn get avatarColor => integer()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderHour => integer().withDefault(const Constant(19))();
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Планы обучения. У пользователя может быть несколько планов, один активный.
@DataClassName('PlanRow')
class Plans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get directionId => text()();
  TextColumn get title => text()();
  RealColumn get hoursPerWeek => real()();

  /// Учебные дни через запятую: «1,3,5» (1 — понедельник).
  TextColumn get studyDays => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get deadline => dateTime().nullable()();

  /// Темы, исключённые по тесту, через запятую.
  TextColumn get knownTopicIds => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Темы в составе плана — снимок, чтобы план не зависел от изменений каталога.
@DataClassName('PlanTopicRow')
class PlanTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  TextColumn get topicId => text()();
  TextColumn get title => text()();
  TextColumn get category => text()();
  IntColumn get minutes => integer()();
  IntColumn get level => integer()();
  TextColumn get prerequisites => text().withDefault(const Constant(''))();
  IntColumn get position => integer()();
}

/// Занятия плана (изучение темы или повторение) на конкретную дату.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();
  TextColumn get topicId => text()();
  TextColumn get topicTitle => text()();
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get minutes => integer()();

  /// «study» или «review».
  TextColumn get kind => text()();
  IntColumn get part => integer().withDefault(const Constant(1))();
  IntColumn get totalParts => integer().withDefault(const Constant(1))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Собственные темы пользователя.
@DataClassName('CustomTopicRow')
class CustomTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get directionId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get minutes => integer()();
  TextColumn get category => text()();
  TextColumn get prerequisites => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}

/// Заметки пользователя.
@DataClassName('NoteRow')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get topicId => text().nullable()();
  TextColumn get topicTitle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// Избранные темы.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get topicId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, topicId};
}

/// Завершённые интервалы Pomodoro.
@DataClassName('PomodoroLogRow')
class PomodoroLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  IntColumn get minutes => integer()();
  TextColumn get topicTitle => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Users,
    Plans,
    PlanTopics,
    Sessions,
    CustomTopics,
    Notes,
    Favorites,
    PomodoroLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Включаем проверку внешних ключей (каскадное удаление планов и занятий).
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

# ПРИЛОЖЕНИЕ Ж. ПРАВИЛО ДОСТУПА К ЭКРАНАМ И МАРШРУТЫ

Файл `lib/core/router/app_router.dart`.

```dart
/// Маршруты, доступные без входа в систему.
const publicRoutes = {'/login', '/register'};

/// Правило доступа к экранам (вынесено в функцию, чтобы его можно было
/// проверить юнит-тестом без запуска интерфейса).
///
/// * пока сессия не проверена — показываем только Splash;
/// * неавторизованный пользователь видит только вход и регистрацию;
/// * авторизованного пользователя с экранов входа и Splash ведём на главную.
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  if (status == AuthStatus.unknown) {
    return location == '/splash' ? null : '/splash';
  }
  final loggedIn = status == AuthStatus.authenticated;
  final isPublic = publicRoutes.contains(location);
  if (!loggedIn) return isPublic ? null : '/login';
  if (isPublic || location == '/splash') return '/home';
  return null;
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Роутер пересчитывает redirect каждый раз, когда меняется состояние входа.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          initialEmail: state.uri.queryParameters['email'],
          justRegistered: state.uri.queryParameters['registered'] == '1',
        ),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Онбординг: создание нового плана.
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const DirectionScreen(),
        routes: [
          GoRoute(path: 'test', builder: (_, _) => const DiagnosticScreen()),
          GoRoute(path: 'schedule', builder: (_, _) => const ScheduleScreen()),
          GoRoute(path: 'preview', builder: (_, _) => const PreviewScreen()),
        ],
      ),

      // Основные вкладки с нижней навигацией.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/topics', builder: (_, _) => const TopicsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Экраны поверх вкладок.
      GoRoute(
        path: '/session/:id',
        builder: (_, state) =>
            SessionScreen(sessionId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      GoRoute(
        path: '/plan/settings',
        builder: (_, _) => const PlanSettingsScreen(),
      ),
      GoRoute(
        path: '/pomodoro',
        builder: (_, state) =>
            PomodoroScreen(topicTitle: state.uri.queryParameters['topic']),
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/topics/custom/new',
        builder: (_, state) => CustomTopicScreen(
          directionId: state.uri.queryParameters['direction'],
        ),
      ),
      GoRoute(
        path: '/topics/custom/:id',
        builder: (_, state) =>
            CustomTopicScreen(topicId: state.pathParameters['id']),
      ),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      GoRoute(
        path: '/notes/edit',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return NoteEditScreen(
            // Новый ключ для каждой заметки: иначе при переходе между
            // заметками сохранялось бы состояние предыдущей.
            key: ValueKey(state.uri.toString()),
            noteId: int.tryParse(q['id'] ?? ''),
            topicId: q['topicId'],
            topicTitle: q['topicTitle'],
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
```

# ПРИЛОЖЕНИЕ И. МОДУЛЬНЫЕ ТЕСТЫ ТОПОЛОГИЧЕСКОЙ СОРТИРОВКИ

Файл `test/domain/topological_sort_test.dart`.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/topological_sort.dart';

Topic t(String id, {List<String> deps = const [], int level = 1}) => Topic(
  id: id,
  title: id,
  minutes: 60,
  category: 'Тест',
  level: level,
  prerequisites: deps,
);

List<String> ids(List<Topic> topics) => topics.map((t) => t.id).toList();

void main() {
  group('topologicalSort (алгоритм Кана)', () {
    test('каждая тема идёт после всех своих зависимостей', () {
      final topics = [
        t('riverpod', deps: ['widgets', 'async']),
        t('widgets', deps: ['dart']),
        t('async', deps: ['dart']),
        t('dart'),
      ];

      final order = ids(topologicalSort(topics));

      expect(order.first, 'dart');
      expect(order.last, 'riverpod');
      for (final topic in topics) {
        for (final dep in topic.prerequisites) {
          expect(
            order.indexOf(dep) < order.indexOf(topic.id),
            isTrue,
            reason: '$dep должна идти раньше ${topic.id}',
          );
        }
      }
    });

    test(
      'независимые темы упорядочены по уровню, затем по исходной позиции',
      () {
        final topics = [
          t('hard', level: 3),
          t('easy_b', level: 1),
          t('medium', level: 2),
          t('easy_a', level: 1),
        ];

        expect(ids(topologicalSort(topics)), [
          'easy_b',
          'easy_a',
          'medium',
          'hard',
        ]);
      },
    );

    test('зависимость, которой нет в наборе, считается выполненной', () {
      final topics = [
        t('b', deps: ['known_topic']),
        t('a'),
      ];

      expect(ids(topologicalSort(topics)), ['b', 'a']);
    });

    test('повторяющаяся зависимость не ломает подсчёт степени', () {
      final topics = [
        t('b', deps: ['a', 'a']),
        t('a'),
      ];

      expect(ids(topologicalSort(topics)), ['a', 'b']);
    });

    test('пустой список даёт пустой результат', () {
      expect(topologicalSort(const []), isEmpty);
    });

    test('цикл в графе обнаруживается', () {
      final topics = [
        t('a', deps: ['c']),
        t('b', deps: ['a']),
        t('c', deps: ['b']),
        t('free'),
      ];

      expect(
        () => topologicalSort(topics),
        throwsA(
          isA<CycleDetectedException>().having(
            (e) => e.topicIds,
            'topicIds',
            unorderedEquals(['a', 'b', 'c']),
          ),
        ),
      );
    });
  });
}
```
