<!-- Файл создан tool/coursework/build_coursework.py из исходного кода. Не редактируйте вручную. -->

# ПРИЛОЖЕНИЕ А. ТОПОЛОГИЧЕСКАЯ СОРТИРОВКА ТЕМ (АЛГОРИТМ КАНА)

Файл `lib/domain/planner/topological_sort.dart`.

```dart
// Топологическая сортировка тем алгоритмом Кана (слой domain, planner).
// Топологическая сортировка — такой порядок вершин графа, при котором каждая
// тема стоит после всех тем, от которых она зависит. Используется в
// PlanGenerator (шаг 3 построения плана) и в PlanService.addTopic().

import 'dart:collection';

import '../entities/topic.dart';

/// В графе тем обнаружен цикл, поэтому порядок изучения построить нельзя.
///
/// Цикл — это ситуация, когда темы зависят друг от друга по кругу
/// (A требует B, а B требует A), и ни одну из них нельзя начать первой.
class CycleDetectedException implements Exception {
  /// Создаёт исключение со списком тем [topicIds], которые не удалось
  /// упорядочить.
  CycleDetectedException(this.topicIds);

  /// Темы, которые остались неупорядоченными (входят в цикл или зависят
  /// от него).
  final List<String> topicIds;

  /// Текст ошибки: перечисляет проблемные темы через запятую.
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
/// (V — число тем, E — число связей «тема → зависимость».)
List<Topic> topologicalSort(List<Topic> topics) {
  // Словарь «id темы → её позиция в списке». Дальше алгоритм работает
  // с номерами тем (индексами), а не с самими объектами — так проще.
  final index = <String, int>{
    for (var i = 0; i < topics.length; i++) topics[i].id: i,
  };
  // inDegree[i] — входящая степень темы i: сколько её зависимостей ещё
  // не поставлено в результат. Сначала у всех тем 0.
  final inDegree = List<int>.filled(topics.length, 0);
  // dependents[i] — номера тем, которые зависят от темы i
  // (рёбра графа в направлении «предшественник → зависимая тема»).
  final dependents = List.generate(topics.length, (_) => <int>[]);

  // Шаг 1 алгоритма: строим рёбра графа и считаем входящие степени.
  for (var i = 0; i < topics.length; i++) {
    // toSet() убирает повторы, если одна зависимость указана дважды.
    for (final prerequisite in topics[i].prerequisites.toSet()) {
      // Ищем номер темы-предшественника в переданном наборе.
      final from = index[prerequisite];
      if (from == null) continue; // зависимость уже изучена или вне плана
      // Запоминаем ребро «предшественник → тема i».
      dependents[from].add(i);
      // У темы i стало на одну невыполненную зависимость больше.
      inDegree[i]++;
    }
  }

  // Правило сравнения для очереди: раньше идёт тема с меньшим уровнем
  // сложности, а при равном уровне — та, что раньше стояла в списке.
  int compare(int a, int b) {
    // Сравниваем уровни сложности двух тем.
    final byLevel = topics[a].level.compareTo(topics[b].level);
    // Уровни разные — решает уровень, одинаковые — исходная позиция.
    return byLevel != 0 ? byLevel : a.compareTo(b);
  }

  // Шаг 2: очередь с приоритетом. SplayTreeSet — множество, которое само
  // держит элементы отсортированными по compare, поэтому первый элемент
  // всегда самый приоритетный.
  final queue = SplayTreeSet<int>(compare);
  // Кладём в очередь все темы без зависимостей — их можно учить сразу.
  for (var i = 0; i < topics.length; i++) {
    if (inDegree[i] == 0) queue.add(i);
  }

  // Шаг 3: сюда складываем темы в итоговом порядке изучения.
  final result = <Topic>[];
  // Повторяем, пока есть темы, готовые к изучению.
  while (queue.isNotEmpty) {
    // Берём самую приоритетную тему и убираем её из очереди.
    final current = queue.first;
    queue.remove(current);
    // Ставим её в результат: все её зависимости уже стоят раньше.
    result.add(topics[current]);
    // «Удаляем» исходящие рёбра: каждая зависимая тема теперь ждёт
    // на одну тему меньше.
    for (final next in dependents[current]) {
      inDegree[next]--;
      // Все зависимости темы выполнены — она готова, кладём в очередь.
      if (inDegree[next] == 0) queue.add(next);
    }
  }

  // Шаг 4: если в результат попали не все темы, какие-то темы ждут друг
  // друга по кругу — значит, в графе есть цикл.
  if (result.length != topics.length) {
    // Множество id тем, которые удалось упорядочить.
    final sorted = result.map((t) => t.id).toSet();
    // Сообщаем об ошибке и перечисляем темы, оставшиеся без места.
    throw CycleDetectedException(
      topics.where((t) => !sorted.contains(t.id)).map((t) => t.id).toList(),
    );
  }
  // Цикла нет — возвращаем темы в порядке изучения.
  return result;
}
```

# ПРИЛОЖЕНИЕ Б. ХЭШИРОВАНИЕ ПАРОЛЕЙ PBKDF2-HMAC-SHA256

Файл `lib/core/utils/password_hasher.dart`.

```dart
// Файл password_hasher.dart — безопасное хранение паролей (хэширование).
// Слой: core (утилиты). Пароль никогда не хранится в открытом виде: в базу
// попадают только соль и хэш. Класс использует AuthRepositoryImpl
// (data/repositories) при регистрации, входе и смене пароля; работает он
// на сервере API (lib/server/api_server.dart), а не в приложении.
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Хэширование паролей алгоритмом PBKDF2-HMAC-SHA256 (RFC 8018).
///
/// Хэш — это «отпечаток» строки фиксированной длины, по которому нельзя
/// восстановить сам пароль, но можно проверить, совпадает ли введённый.
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
  /// Создаёт хэшер. [random] можно подменить в тестах; по умолчанию —
  /// криптостойкий [Random.secure]. [iterations] должно быть больше нуля.
  PasswordHasher({Random? random, this.iterations = defaultIterations})
    : assert(iterations > 0),
      _random = random ?? Random.secure();

  /// Число итераций по умолчанию: заметно замедляет перебор и при этом
  /// не задерживает вход на телефоне дольше долей секунды.
  static const defaultIterations = 100000;

  /// Название схемы — первая часть сохранённой строки хэша.
  static const _scheme = 'pbkdf2_sha256';

  /// Сколько раз повторяется HMAC при расчёте нового хэша.
  final int iterations;

  /// Генератор случайных чисел для соли.
  final Random _random;

  /// Создаёт новую случайную соль: [length] случайных байт, записанных
  /// текстом в кодировке base64url (только безопасные для URL символы).
  String generateSalt([int length = 16]) {
    // Список из length случайных чисел от 0 до 255 (то есть байтов).
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    // Переводим байты в строку, чтобы хранить соль в базе как текст.
    return base64Url.encode(bytes);
  }

  /// Хэш пароля в текущем формате.
  ///
  /// Пароль и соль переводятся в байты UTF-8, прогоняются через [pbkdf2]
  /// и записываются в виде `pbkdf2_sha256$<итерации>$<hex>`.
  String hash(String password, String salt) => _format(
    iterations,
    pbkdf2(utf8.encode(password), utf8.encode(salt), iterations),
  );

  /// [hash] в фоновом изоляте, чтобы интерфейс не замирал на время расчёта.
  ///
  /// Изолят — отдельный поток выполнения Dart со своей памятью; функция
  /// [Isolate.run] запускает в нём вычисление и возвращает результат.
  Future<String> hashAsync(String password, String salt) {
    // При малом числе итераций (например, в тестах) считаем сразу.
    if (iterations < _isolateThreshold) {
      return Future.value(hash(password, salt));
    }
    // Копируем число итераций в локальную переменную: в изолят уходит
    // только это число, а не весь текущий объект.
    final rounds = iterations;
    // В изоляте создаём новый хэшер с тем же числом итераций и считаем хэш.
    return Isolate.run(
      () => PasswordHasher(iterations: rounds).hash(password, salt),
    );
  }

  /// [verify] в фоновом изоляте.
  Future<bool> verifyAsync(String password, String salt, String stored) {
    // Узнаём число итераций из сохранённого хэша; у старого формата
    // его нет — считаем, что итерация одна.
    final rounds = _iterationsOf(stored) ?? 1;
    // Быстрый расчёт выполняем сразу, без изолята.
    if (rounds < _isolateThreshold) {
      return Future.value(verify(password, salt, stored));
    }
    // Долгую проверку уносим в изолят. Число итераций в конструкторе здесь
    // не важно: verify берёт его из сохранённой строки хэша.
    return Isolate.run(
      () => PasswordHasher(iterations: 1).verify(password, salt, stored),
    );
  }

  /// При малом числе итераций запуск изолята дороже самого вычисления.
  static const _isolateThreshold = 10000;

  /// Хэш старого формата (версия 1 семестра): SHA-256 от «соль + пароль».
  static String legacyHash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// Проверяет, подходит ли [password] к сохранённому хэшу [stored].
  ///
  /// Понимает оба формата: новый PBKDF2 и старый [legacyHash].
  bool verify(String password, String salt, String stored) {
    // Здесь будет хэш введённого пароля, посчитанный тем же способом.
    final String actual;
    // Число итераций из сохранённой строки (null — старый формат).
    final rounds = _iterationsOf(stored);
    if (rounds != null) {
      // Новый формат: считаем PBKDF2 с тем же числом итераций.
      actual = _format(
        rounds,
        pbkdf2(utf8.encode(password), utf8.encode(salt), rounds),
      );
    } else {
      // Старый формат: однократный SHA-256.
      actual = legacyHash(password, salt);
    }
    // Сравниваем хэши за постоянное время (см. _constantTimeEquals).
    return _constantTimeEquals(actual, stored);
  }

  /// `true`, если хэш старого формата или посчитан с меньшим числом итераций.
  bool needsRehash(String stored) {
    // Старый формат даёт null, новый — число итераций.
    final rounds = _iterationsOf(stored);
    // Пересчитать нужно, если формат старый или итераций меньше текущих.
    return rounds == null || rounds < iterations;
  }

  /// PBKDF2 с HMAC-SHA256. Для ключа длиной до 32 байт нужен один блок:
  /// T = U1 ⊕ U2 ⊕ … ⊕ Uc, где U1 = HMAC(P, S ‖ 00000001), Uj = HMAC(P, Uj-1).
  ///
  /// [password] и [salt] — байты, [iterations] — число повторов,
  /// [length] — длина результата в байтах (по умолчанию 32).
  static List<int> pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations, [
    int length = 32,
  ]) {
    // HMAC-SHA256 с паролем в роли ключа — основная функция алгоритма.
    final prf = Hmac(sha256, password);
    // Один блок SHA-256 даёт 32 байта; считаем, сколько блоков нужно
    // (деление с округлением вверх).
    final blocks = (length + 31) ~/ 32;
    // Сюда складываем байты всех блоков подряд.
    final result = <int>[];
    // Блоки нумеруются с единицы.
    for (var block = 1; block <= blocks; block++) {
      // U1 = HMAC(соль + номер блока в виде 4 байт, старший байт первым).
      var u = prf.convert([
        ...salt,
        block >> 24 & 0xff,
        block >> 16 & 0xff,
        block >> 8 & 0xff,
        block & 0xff,
      ]).bytes;
      // T начинается с копии U1.
      final t = List<int>.of(u);
      // Остальные итерации: каждый следующий U — HMAC от предыдущего.
      for (var i = 1; i < iterations; i++) {
        u = prf.convert(u).bytes;
        // Побайтово накапливаем T через XOR (^ — «исключающее или»).
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      // Готовый блок добавляем к результату.
      result.addAll(t);
    }
    // Обрезаем результат до нужной длины.
    return result.sublist(0, length);
  }

  /// Собирает строку хэша для хранения: `pbkdf2_sha256$<итерации>$<hex>`.
  static String _format(int rounds, List<int> key) =>
      '$_scheme\$$rounds\$${_hex(key)}';

  /// Достаёт число итераций из сохранённой строки хэша.
  ///
  /// Возвращает `null`, если строка не в формате PBKDF2 (старый хэш)
  /// или число итераций некорректно.
  static int? _iterationsOf(String stored) {
    // Делим строку по символу «$» на схему, итерации и сам хэш.
    final parts = stored.split(r'$');
    // Частей не три или схема чужая — значит, это не наш новый формат.
    if (parts.length != 3 || parts[0] != _scheme) return null;
    // Пробуем прочитать число итераций.
    final rounds = int.tryParse(parts[1]);
    // Принимаем только положительное число.
    return rounds != null && rounds > 0 ? rounds : null;
  }

  /// Переводит байты в шестнадцатеричную строку (по 2 символа на байт).
  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Сравнение без раннего выхода, чтобы время не зависело от совпадения.
  ///
  /// Обычное сравнение строк останавливается на первом отличии, и по
  /// времени ответа можно угадывать хэш; здесь всегда проверяются все
  /// символы.
  static bool _constantTimeEquals(String a, String b) {
    // Разная длина — точно не совпадают.
    if (a.length != b.length) return false;
    // Накапливаем отличия всех символов через XOR и OR.
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    // Ноль — значит, ни один символ не отличался.
    return diff == 0;
  }
}
```

# ПРИЛОЖЕНИЕ В. РАСКЛАДКА ТЕМ ПО ДНЯМ И ИНТЕРВАЛЬНЫЕ ПОВТОРЕНИЯ

Файл `lib/domain/planner/scheduler.dart`.

```dart
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
```

# ПРИЛОЖЕНИЕ Г. ГЕНЕРАТОР ПЛАНА И ПРОВЕРКА ДЕДЛАЙНА

Файл `lib/domain/planner/plan_generator.dart`.

```dart
// Генератор персонального плана обучения (слой domain, папка planner).
// Собирает вместе все шаги построения плана: исключение известных тем,
// сортировку Кана, раскладку по дням (Scheduler) и проверку дедлайна.
// Используется в PlanService (предпросмотр и создание плана) и в Replanner.

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
  /// Создаёт генератор. [scheduler] можно передать свой (например, в
  /// тестах); по умолчанию — стандартный планировщик с повторениями
  /// через 1, 3 и 7 дней.
  const PlanGenerator({this.scheduler = const Scheduler()});

  /// Планировщик, который раскладывает темы по дням (шаг 4).
  final Scheduler scheduler;

  /// Максимум часов в неделю, который имеет смысл предлагать (12 ч × 7 дней).
  static const double maxHoursPerWeek = 84;

  /// Строит план по темам направления [topics] и расписанию [settings].
  ///
  /// [knownTopicIds] — id тем, которые пользователь уже знает по тесту; они
  /// не попадают в план. Возвращает [PlanResult]: порядок тем, занятия по
  /// датам, дату окончания и признак того, успевает ли план к дедлайну.
  PlanResult generate({
    required List<Topic> topics,
    required ScheduleSettings settings,
    Set<String> knownTopicIds = const {},
  }) {
    // Шаг 2.
    // Темы, которые пользователь уже знает, откладываем отдельно, чтобы
    // показать их на экране как исключённые.
    final excluded = topics.where((t) => knownTopicIds.contains(t.id)).toList();
    // Все остальные темы — их и нужно изучать.
    final remaining = topics
        .where((t) => !knownTopicIds.contains(t.id))
        .toList();

    // Шаг 3.
    // Упорядочиваем темы алгоритмом Кана: каждая тема встаёт после всех
    // тем, от которых она зависит.
    final ordered = topologicalSort(remaining);

    // Шаг 4.
    // Раскладываем темы по учебным дням (повторения добавятся там же).
    final sessions = scheduler.schedule(ordered, settings);
    // День последнего занятия по новой теме — дата окончания плана.
    final finish = lastStudyDate(sessions);

    // Шаг 5.
    // Дедлайн выполнен, если его нет, если занятий нет вообще или если
    // план заканчивается не позже дедлайна.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);

    // Собираем результат. Если дедлайн не выполнен, дополнительно считаем,
    // сколько часов в неделю нужно, чтобы успеть.
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
  ///
  /// [remainingMinutes] — остаток минут по темам; его передаёт Replanner,
  /// когда часть тем уже изучена.
  double? requiredHoursPerWeek(
    List<Topic> orderedTopics,
    ScheduleSettings settings, {
    Map<String, int> remainingMinutes = const {},
  }) {
    // Без дедлайна подбирать нечего.
    final deadline = settings.deadline;
    if (deadline == null) return null;

    // Простой перебор: начинаем с текущих часов + 0,5 и прибавляем
    // по 0,5 ч, пока не дойдём до максимума.
    for (
      var hours = settings.hoursPerWeek + 0.5;
      hours <= maxHoursPerWeek;
      hours += 0.5
    ) {
      // Копия настроек, в которой изменено только число часов в неделю.
      final candidate = settings.copyWith(hoursPerWeek: hours);
      // Пробно раскладываем те же темы с новым дневным лимитом.
      final sessions = scheduler.schedule(
        orderedTopics,
        candidate,
        remainingMinutes: remainingMinutes,
      );
      // Смотрим, когда закончится такой пробный план.
      final finish = lastStudyDate(sessions);
      // Успеваем к дедлайну — это и есть минимальное подходящее значение.
      if (finish == null || !finish.isAfter(deadline)) return hours;
    }
    // Даже максимума не хватает — дедлайн невыполним.
    return null;
  }

  /// Находит дату последнего занятия типа «изучение»; повторения не
  /// учитываются. Возвращает `null`, если таких занятий нет.
  /// Метод статический (не требует объекта), его вызывает и Replanner.
  static DateTime? lastStudyDate(List<PlannedSession> sessions) {
    // Самая поздняя найденная дата (пока ничего не нашли).
    DateTime? last;
    // Просматриваем все занятия по очереди.
    for (final s in sessions) {
      // Повторения пропускаем: план закончен, когда изучена последняя тема.
      if (s.kind != SessionKind.study) continue;
      // Запоминаем дату, если она позже уже найденной.
      if (last == null || s.date.isAfter(last)) last = s.date;
    }
    // Возвращаем самую позднюю дату изучения.
    return last;
  }
}
```

# ПРИЛОЖЕНИЕ Д. ПЕРЕПЛАНИРОВАНИЕ

Файл `lib/domain/planner/replanner.dart`.

```dart
// Перепланирование — перестройка плана, когда пользователь отстал или
// поменял расписание (слой domain, папка planner). Выполненные занятия не
// трогаются, а остаток тем заново раскладывается с сегодняшнего дня.
// Вызывается из PlanService.replan().

import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import 'dates.dart';
import 'plan_generator.dart';
import 'scheduler.dart';

/// Результат перепланирования.
class ReplanResult {
  /// Создаёт результат; все поля, кроме [requiredHoursPerWeek], обязательны.
  const ReplanResult({
    required this.sessions,
    required this.finishDate,
    required this.deadlineMet,
    this.requiredHoursPerWeek,
  });

  /// Новые невыполненные занятия, начиная с сегодняшнего дня.
  final List<PlannedSession> sessions;

  /// Новая дата окончания — день последнего занятия по изучению темы
  /// (`null`, если изучать больше нечего).
  final DateTime? finishDate;

  /// `true`, если план укладывается в дедлайн или дедлайн не задан.
  final bool deadlineMet;

  /// Сколько часов в неделю нужно, чтобы успеть к дедлайну. Заполняется,
  /// только если [deadlineMet] равно `false`; `null` в этом случае значит,
  /// что не успеть даже при максимуме часов.
  final double? requiredHoursPerWeek;
}

/// Перестраивает план, если пользователь отстал или изменил расписание.
///
/// Выполненные занятия остаются на своих местах. Для каждой темы считается,
/// сколько минут уже изучено; остаток заново раскладывается начиная с
/// [today] теми же правилами, что и при генерации. Невыполненные повторения
/// по уже изученным темам переносятся на ближайшие учебные дни.
class Replanner {
  /// Создаёт перепланировщик. [scheduler] можно подменить (например, в
  /// тестах); по умолчанию — стандартный планировщик.
  const Replanner({this.scheduler = const Scheduler()});

  /// Планировщик, который заново раскладывает остаток тем по дням.
  final Scheduler scheduler;

  /// Перестраивает план.
  ///
  /// [orderedTopics] — темы плана в порядке изучения; [sessions] — все
  /// сохранённые занятия плана (выполненные и нет); [settings] — расписание;
  /// [today] — сегодняшняя дата, с неё начинается новое расписание.
  ReplanResult replan({
    required List<Topic> orderedTopics,
    required List<StudySession> sessions,
    required ScheduleSettings settings,
    required DateTime today,
  }) {
    // Новое расписание начинается с сегодняшнего дня (без времени суток).
    final start = dateOnly(today);

    // Считаем, сколько минут по каждой теме уже изучено: складываем
    // минуты выполненных занятий типа «изучение».
    final doneMinutes = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneMinutes[s.topicId] = (doneMinutes[s.topicId] ?? 0) + s.minutes;
      }
    }

    // Остаток по каждой теме = длительность темы − уже изучено.
    // clamp() не даёт остатку уйти ниже 0 и выше полной длительности.
    final remaining = <String, int>{
      for (final t in orderedTopics)
        t.id: (t.minutes - (doneMinutes[t.id] ?? 0)).clamp(0, t.minutes),
    };

    // Невыполненные повторения тем, которые уже изучены полностью.
    // Их не теряем, а передаём планировщику как начальные повторения.
    final pendingReviews = <PendingReview>[
      for (final s in sessions)
        if (!s.isDone &&
            s.kind == SessionKind.review &&
            remaining[s.topicId] == 0)
          PendingReview(
            topicId: s.topicId,
            topicTitle: s.topicTitle,
            category: s.category,
            // Просроченное повторение переносим на сегодня, будущее
            // оставляем на его дату.
            dueDate: s.date.isBefore(start) ? start : s.date,
          ),
    ];

    // Копия настроек, у которой дата старта заменена на сегодня.
    final newSettings = settings.copyWith(startDate: start);
    // Раскладываем остаток тем тем же планировщиком, что и при создании
    // плана: передаём остатки минут и перенесённые повторения.
    final planned = scheduler.schedule(
      orderedTopics,
      newSettings,
      remainingMinutes: remaining,
      initialReviews: pendingReviews,
    );

    // Номера частей продолжают уже выполненные части темы.
    // Сначала считаем, сколько частей каждой темы уже выполнено.
    final doneParts = <String, int>{};
    for (final s in sessions) {
      if (s.isDone && s.kind == SessionKind.study) {
        doneParts[s.topicId] = (doneParts[s.topicId] ?? 0) + 1;
      }
    }
    // Сдвигаем номера: если 2 части темы уже пройдены, новая «часть 1»
    // становится «частью 3», а общее число частей тоже растёт на 2.
    // Повторения и темы без выполненных частей остаются как есть.
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

    // Новая дата окончания — день последнего занятия по изучению.
    final finish = PlanGenerator.lastStudyDate(renumbered);
    // Проверяем дедлайн так же, как при генерации плана.
    final deadline = settings.deadline;
    final met = deadline == null || finish == null || !finish.isAfter(deadline);
    // Собираем результат. Если не успеваем, подбираем нужное число часов
    // в неделю с учётом того, что часть тем уже изучена.
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
// Описание базы данных SQLite через библиотеку drift (слой data, папка db).
// drift — пакет для работы с SQLite: по таблицам, описанным классами Dart,
// он генерирует код запросов (файл app_database.g.dart, вручную не правится).
// Базу открывает сервер API (bin/marshrut_server.dart), а работают с ней
// репозитории lib/data/repositories. Приложение к базе напрямую не обращается:
// все данные оно получает от сервера через API.

import 'package:drift/drift.dart';

// Подключаем сгенерированную часть этого файла (код запросов drift).
part 'app_database.g.dart';

// Таблицы базы данных SQLite. Код запросов генерирует drift:
//   dart run build_runner build
// Сгенерированный файл app_database.g.dart хранится в репозитории, поэтому
// для запуска приложения генерация не нужна.

/// Пользователи. Пароль хранится только в виде хэша PBKDF2-HMAC-SHA256 с солью
/// (записи версии 1 семестра с хэшем SHA-256 пересчитываются при входе).
///
/// Каждый геттер класса — столбец таблицы. Аннотация `@DataClassName`
/// задаёт имя класса одной строки таблицы (здесь UserRow), который
/// сгенерирует drift.
@DataClassName('UserRow')
class Users extends Table {
  /// Уникальный номер пользователя; база назначает его сама
  /// (autoIncrement — каждая новая запись получает следующий номер).
  IntColumn get id => integer().autoIncrement()();

  /// Имя пользователя (от 2 до 40 символов).
  TextColumn get name => text().withLength(min: 2, max: 40)();

  /// Email — уникальный (два аккаунта с одним email создать нельзя).
  TextColumn get email => text().unique()();

  /// Хэш пароля — результат необратимого преобразования пароля.
  /// Сам пароль в базе не хранится.
  TextColumn get passwordHash => text()();

  /// Соль — случайная строка, которая добавляется к паролю перед
  /// хэшированием, чтобы одинаковые пароли давали разные хэши.
  TextColumn get salt => text()();

  /// Цвет аватара, записанный числом.
  IntColumn get avatarColor => integer()();

  /// Включено ли ежедневное напоминание (по умолчанию выключено).
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Час ежедневного напоминания (по умолчанию 19).
  IntColumn get reminderHour => integer().withDefault(const Constant(19))();

  /// Минуты ежедневного напоминания (по умолчанию 0).
  IntColumn get reminderMinute => integer().withDefault(const Constant(0))();

  /// Дата и время регистрации.
  DateTimeColumn get createdAt => dateTime()();
}

/// Планы обучения. У пользователя может быть несколько планов, один активный.
@DataClassName('PlanRow')
class Plans extends Table {
  /// Уникальный номер плана (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Владелец плана — ссылка (внешний ключ) на таблицу Users. При удалении
  /// пользователя его планы удаляются автоматически (каскадно).
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// id направления из каталога, по которому построен план.
  TextColumn get directionId => text()();

  /// Название плана.
  TextColumn get title => text()();

  /// Сколько часов в неделю пользователь готов учиться.
  RealColumn get hoursPerWeek => real()();

  /// Учебные дни через запятую: «1,3,5» (1 — понедельник).
  TextColumn get studyDays => text()();

  /// Дата начала обучения.
  DateTimeColumn get startDate => dateTime()();

  /// Дедлайн. nullable — значение может отсутствовать (план без дедлайна).
  DateTimeColumn get deadline => dateTime().nullable()();

  /// Темы, исключённые по тесту, через запятую.
  TextColumn get knownTopicIds => text().withDefault(const Constant(''))();

  /// Активный ли это план (по умолчанию — да).
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Дата и время создания плана.
  DateTimeColumn get createdAt => dateTime()();
}

/// Темы в составе плана — снимок, чтобы план не зависел от изменений каталога.
@DataClassName('PlanTopicRow')
class PlanTopics extends Table {
  /// Уникальный номер записи (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// План, к которому относится тема; удаляется вместе с планом.
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();

  /// id темы (из каталога или собственной темы пользователя).
  TextColumn get topicId => text()();

  /// Название темы.
  TextColumn get title => text()();

  /// Категория темы.
  TextColumn get category => text()();

  /// Длительность изучения темы в минутах.
  IntColumn get minutes => integer()();

  /// Уровень сложности темы (влияет на порядок при сортировке Кана).
  IntColumn get level => integer()();

  /// id тем-зависимостей через запятую (пустая строка — зависимостей нет).
  TextColumn get prerequisites => text().withDefault(const Constant(''))();

  /// Позиция темы в порядке изучения.
  IntColumn get position => integer()();
}

/// Занятия плана (изучение темы или повторение) на конкретную дату.
@DataClassName('SessionRow')
class Sessions extends Table {
  /// Уникальный номер занятия (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// План, к которому относится занятие; удаляется вместе с планом.
  IntColumn get planId =>
      integer().references(Plans, #id, onDelete: KeyAction.cascade)();

  /// id темы занятия.
  TextColumn get topicId => text()();

  /// Название темы (копия, чтобы не искать тему при показе списка).
  TextColumn get topicTitle => text()();

  /// Категория темы.
  TextColumn get category => text()();

  /// Дата занятия.
  DateTimeColumn get date => dateTime()();

  /// Длительность занятия в минутах.
  IntColumn get minutes => integer()();

  /// «study» или «review».
  TextColumn get kind => text()();

  /// Номер части темы (по умолчанию 1).
  IntColumn get part => integer().withDefault(const Constant(1))();

  /// Сколько всего частей у темы (по умолчанию 1).
  IntColumn get totalParts => integer().withDefault(const Constant(1))();

  /// Выполнено ли занятие (по умолчанию — нет).
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Когда занятие отмечено выполненным; пусто, если ещё не выполнено.
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Собственные темы пользователя.
@DataClassName('CustomTopicRow')
class CustomTopics extends Table {
  /// Уникальный номер темы (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Автор темы; темы удаляются вместе с пользователем.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Направление, в которое пользователь добавил тему.
  TextColumn get directionId => text()();

  /// Название темы.
  TextColumn get title => text()();

  /// Описание темы (по умолчанию пустое).
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Длительность изучения в минутах.
  IntColumn get minutes => integer()();

  /// Категория темы.
  TextColumn get category => text()();

  /// id тем-зависимостей через запятую.
  TextColumn get prerequisites => text().withDefault(const Constant(''))();

  /// Дата и время создания темы.
  DateTimeColumn get createdAt => dateTime()();
}

/// Заметки пользователя.
@DataClassName('NoteRow')
class Notes extends Table {
  /// Уникальный номер заметки (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Автор заметки; заметки удаляются вместе с пользователем.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Заголовок заметки.
  TextColumn get title => text()();

  /// Текст заметки.
  TextColumn get body => text()();

  /// id темы, к которой привязана заметка (может отсутствовать).
  TextColumn get topicId => text().nullable()();

  /// Название этой темы (может отсутствовать).
  TextColumn get topicTitle => text().nullable()();

  /// Когда заметка создана.
  DateTimeColumn get createdAt => dateTime()();

  /// Когда заметку изменяли последний раз.
  DateTimeColumn get updatedAt => dateTime()();
}

/// Избранные темы.
@DataClassName('FavoriteRow')
class Favorites extends Table {
  /// Пользователь; записи удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// id избранной темы.
  TextColumn get topicId => text()();

  /// Когда тема добавлена в избранное.
  DateTimeColumn get createdAt => dateTime()();

  /// Составной первичный ключ: пара (пользователь, тема) уникальна,
  /// поэтому одну тему нельзя добавить в избранное дважды.
  @override
  Set<Column> get primaryKey => {userId, topicId};
}

/// Завершённые интервалы Pomodoro.
@DataClassName('PomodoroLogRow')
class PomodoroLogs extends Table {
  /// Уникальный номер записи (назначается автоматически).
  IntColumn get id => integer().autoIncrement()();

  /// Пользователь; записи удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Длительность интервала в минутах.
  IntColumn get minutes => integer()();

  /// Тема, над которой шла работа (может отсутствовать).
  TextColumn get topicTitle => text().nullable()();

  /// Когда интервал завершён.
  DateTimeColumn get completedAt => dateTime()();
}

/// Токены входа в API. После входа сервер выдаёт приложению случайный
/// токен, а приложение отправляет его с каждым запросом. В таблице хранится
/// только хэш SHA-256 токена: даже по копии базы войти не получится.
@DataClassName('ApiTokenRow')
class ApiTokens extends Table {
  /// Хэш SHA-256 токена (64 шестнадцатеричных символа).
  TextColumn get tokenHash => text()();

  /// Пользователь, которому выдан токен; токены удаляются вместе с ним.
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();

  /// Когда токен выдан: по этой дате сервер отбрасывает старые токены.
  DateTimeColumn get createdAt => dateTime()();

  /// Первичный ключ — сам хэш токена.
  @override
  Set<Column> get primaryKey => {tokenHash};
}

/// База данных приложения.
///
/// Аннотация `@DriftDatabase` перечисляет все таблицы; по ней drift
/// генерирует базовый класс `_$AppDatabase` с доступом к таблицам.
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
    ApiTokens,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Принимает executor — «движок», через который drift работает с SQLite.
  /// На сервере это файл базы на компьютере (создаётся в
  /// bin/marshrut_server.dart), в тестах — база в памяти.
  AppDatabase(super.executor);

  /// Версия схемы базы. Её увеличивают при изменении таблиц, чтобы drift
  /// запустил миграцию (обновление структуры старой базы).
  /// Версия 2 добавила таблицу токенов API.
  @override
  int get schemaVersion => 2;

  /// Стратегия миграции: что делать при создании и открытии базы.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    // При первом запуске создаём все таблицы.
    onCreate: (m) => m.createAll(),
    // База старой версии: добавляем таблицы, которых в ней ещё нет.
    onUpgrade: (m, from, to) async {
      // В версии 1 не было таблицы токенов API.
      if (from < 2) await m.createTable(apiTokens);
    },
    // Выполняется перед каждым открытием базы.
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
///
/// Возвращает адрес, куда нужно перенаправить, или `null`, если можно
/// остаться на запрошенном экране [location].
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  // Статус ещё неизвестен (сессия проверяется): держим пользователя
  // на заставке, любой другой адрес перенаправляем на '/splash'.
  if (status == AuthStatus.unknown) {
    return location == '/splash' ? null : '/splash';
  }
  // Вошёл ли пользователь и открыт ли сейчас публичный экран.
  final loggedIn = status == AuthStatus.authenticated;
  final isPublic = publicRoutes.contains(location);
  // Гостя пускаем только на публичные экраны, остальное — на вход.
  if (!loggedIn) return isPublic ? null : '/login';
  // Вошедшему незачем видеть вход, регистрацию и заставку — ведём на главную.
  if (isPublic || location == '/splash') return '/home';
  // Во всех остальных случаях перенаправление не нужно.
  return null;
}

/// Ключ корневого навигатора: через него роутер управляет стеком экранов.
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Провайдер Riverpod (объект, который создаёт и раздаёт зависимость
/// виджетам), хранящий единственный экземпляр роутера [GoRouter].
///
/// Содержит полную карту экранов приложения и правило доступа
/// [authRedirect].
final routerProvider = Provider<GoRouter>((ref) {
  // Роутер пересчитывает redirect каждый раз, когда меняется состояние входа.
  // ValueNotifier — простой «сигнал»: увеличиваем число, роутер это слышит.
  final refresh = ValueNotifier<int>(0);
  // Подписываемся на контроллер авторизации: любое изменение -> сигнал.
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  // Освобождаем сигнал, когда провайдер уничтожается.
  ref.onDispose(refresh.dispose);

  // Создаём сам роутер с настройками и списком маршрутов.
  final router = GoRouter(
    // Корневой навигатор приложения.
    navigatorKey: _rootKey,
    // При запуске всегда открываем заставку.
    initialLocation: '/splash',
    // Перепроверять redirect при каждом сигнале refresh.
    refreshListenable: refresh,
    // Перед каждым переходом спрашиваем authRedirect, пускать ли на экран.
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    // Список всех маршрутов (путь -> экран).
    routes: [
      // Заставка при запуске.
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      // Экран входа. Параметры адреса: email — подставить в поле,
      // registered=1 — показать сообщение об успешной регистрации.
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          initialEmail: state.uri.queryParameters['email'],
          justRegistered: state.uri.queryParameters['registered'] == '1',
        ),
      ),
      // Экран регистрации.
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Онбординг: создание нового плана.
      // Шаги: выбор направления -> тест -> расписание -> предпросмотр.
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const DirectionScreen(),
        // Вложенные пути: /onboarding/test, /onboarding/schedule и т. д.
        routes: [
          GoRoute(path: 'test', builder: (_, _) => const DiagnosticScreen()),
          GoRoute(path: 'schedule', builder: (_, _) => const ScheduleScreen()),
          GoRoute(path: 'preview', builder: (_, _) => const PreviewScreen()),
        ],
      ),

      // Основные вкладки с нижней навигацией.
      // indexedStack хранит все вкладки в памяти, поэтому при переключении
      // каждая сохраняет своё состояние (прокрутку, введённые данные).
      StatefulShellRoute.indexedStack(
        // MainShell — оболочка с панелью навигации вокруг текущей вкладки.
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        // Каждая ветка — отдельная вкладка со своей историей переходов.
        branches: [
          // Вкладка «Главная».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          // Вкладка «План».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          // Вкладка «Темы».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/topics', builder: (_, _) => const TopicsScreen()),
            ],
          ),
          // Вкладка «Статистика».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
            ],
          ),
          // Вкладка «Профиль».
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
      // Занятие по его номеру id из адреса (например, /session/5).
      GoRoute(
        path: '/session/:id',
        builder: (_, state) =>
            SessionScreen(sessionId: int.parse(state.pathParameters['id']!)),
      ),
      // Список всех планов пользователя.
      GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      // Настройки текущего плана.
      GoRoute(
        path: '/plan/settings',
        builder: (_, _) => const PlanSettingsScreen(),
      ),
      // Таймер Помодоро; параметр topic — название темы для подписи на экране.
      GoRoute(
        path: '/pomodoro',
        builder: (_, state) =>
            PomodoroScreen(topicTitle: state.uri.queryParameters['topic']),
      ),
      // Карточка одной темы по её строковому id.
      GoRoute(
        path: '/topic/:id',
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['id']!),
      ),
      // Создание своей темы; direction — направление, куда её добавить.
      // Этот маршрут стоит выше '/topics/custom/:id', чтобы слово 'new'
      // не приняли за id.
      GoRoute(
        path: '/topics/custom/new',
        builder: (_, state) => CustomTopicScreen(
          directionId: state.uri.queryParameters['direction'],
        ),
      ),
      // Редактирование своей темы по её id.
      GoRoute(
        path: '/topics/custom/:id',
        builder: (_, state) =>
            CustomTopicScreen(topicId: state.pathParameters['id']),
      ),
      // Список заметок.
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      // Создание или редактирование заметки.
      GoRoute(
        path: '/notes/edit',
        builder: (_, state) {
          // Параметры адреса: id заметки (если редактируем) и тема,
          // к которой заметка привязана.
          final q = state.uri.queryParameters;
          return NoteEditScreen(
            // Новый ключ для каждой заметки: иначе при переходе между
            // заметками сохранялось бы состояние предыдущей.
            key: ValueKey(state.uri.toString()),
            // Нет id или он не число — значит, создаётся новая заметка.
            noteId: int.tryParse(q['id'] ?? ''),
            topicId: q['topicId'],
            topicTitle: q['topicTitle'],
          );
        },
      ),
      // Редактирование профиля (имя, email).
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      // Смена пароля.
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
  // Освобождаем ресурсы роутера, когда провайдер уничтожается.
  ref.onDispose(router.dispose);
  // Отдаём готовый роутер всем, кто его читает.
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

# ПРИЛОЖЕНИЕ К. СЕРВЕР API: АДРЕСА, МАРШРУТЫ, ПРОВЕРКА ТОКЕНА И ОБРАБОТКА ОШИБОК

<!-- Текст перед листингом приложения К; вставляется tool/coursework/build_coursework.py. -->

Все адреса, кроме проверки связи, каталога, регистрации и входа, требуют заголовок `Authorization: Bearer <токен>`. Тела запросов и ответов передаются в формате JSON.

Таблица К.1 — Адреса API сервера

| Метод | Адрес | Назначение |
|---|---|---|
| GET | `/api/health` | Проверка связи |
| GET | `/api/directions` | Каталог направлений и тем |
| POST | `/api/auth/register` | Регистрация |
| POST | `/api/auth/login` | Вход, выдача токена |
| POST | `/api/auth/logout` | Выход, удаление токена |
| GET | `/api/me` | Данные своего профиля |
| PUT | `/api/me` | Изменение имени, email и цвета аватара |
| PUT | `/api/me/password` | Смена пароля |
| PUT | `/api/me/reminder` | Время ежедневного напоминания |
| DELETE | `/api/me` | Удаление аккаунта со всеми данными |
| GET | `/api/plans` | Список планов |
| POST | `/api/plans` | Сохранение нового плана |
| GET | `/api/plans/active` | Активный план |
| GET | `/api/plans/{id}` | Один план |
| PATCH | `/api/plans/{id}` | Переименование плана |
| DELETE | `/api/plans/{id}` | Удаление плана с темами и занятиями |
| POST | `/api/plans/{id}/activate` | Сделать план активным |
| PUT | `/api/plans/{id}/settings` | Новые настройки расписания |
| GET | `/api/plans/{id}/topics` | Темы плана по порядку |
| PUT | `/api/plans/{id}/topics` | Новый список тем плана |
| GET | `/api/plans/{id}/sessions` | Занятия плана |
| PUT | `/api/plans/{id}/sessions/open` | Новое расписание невыполненных занятий |
| GET | `/api/sessions/completed` | Выполненные занятия |
| GET | `/api/sessions/{id}` | Одно занятие |
| PUT | `/api/sessions/{id}/done` | Отметка о выполнении |
| GET | `/api/custom-topics` | Свои темы |
| POST | `/api/custom-topics` | Новая своя тема |
| GET | `/api/custom-topics/{id}` | Одна своя тема |
| PUT | `/api/custom-topics/{id}` | Изменение своей темы |
| DELETE | `/api/custom-topics/{id}` | Удаление своей темы |
| GET | `/api/favorites` | Избранные темы |
| POST | `/api/favorites/{id}/toggle` | Добавить в избранное или убрать |
| GET | `/api/notes` | Заметки (все или к одной теме) |
| POST | `/api/notes` | Новая заметка |
| GET | `/api/notes/{id}` | Одна заметка |
| PUT | `/api/notes/{id}` | Изменение заметки |
| DELETE | `/api/notes/{id}` | Удаление заметки |
| GET | `/api/pomodoros` | Журнал Pomodoro |
| POST | `/api/pomodoros` | Запись завершённого интервала |

Файл `lib/server/api_server.dart` (фрагмент).

```dart
/// Сервер API: маршруты (какой адрес что делает) и их обработчики.
class ApiServer {
  /// [db] — база SQLite; [catalog] — направления и темы в виде JSON (как в
  /// файлах assets/catalog); [hasher] — хэширование паролей (в тестах —
  /// быстрое); [log] — куда писать журнал запросов; [clock] — текущее время.
  ApiServer({
    required this.db,
    required this.catalog,
    PasswordHasher? hasher,
    this.log,
    this.tokenLifetime = const Duration(days: 30),
    DateTime Function()? clock,
  }) : _auth = AuthRepositoryImpl(db, hasher: hasher),
       _plans = PlanRepositoryImpl(db),
       _topics = TopicRepositoryImpl(db),
       _notes = NoteRepositoryImpl(db),
       _pomodoros = PomodoroRepositoryImpl(db),
       _clock = clock ?? DateTime.now;

  /// Версия API: приложение может проверить её через /api/health.
  static const apiVersion = 1;

  /// База данных сервера.
  final AppDatabase db;

  /// Каталог направлений (JSON-объекты из файлов assets/catalog).
  final List<Object?> catalog;

  /// Журнал: сюда пишется строка о каждом запросе. `null` — без журнала.
  final void Function(String line)? log;

  /// Сколько действует токен входа.
  final Duration tokenLifetime;

  /// Репозиторий пользователей (регистрация, вход, профиль).
  final AuthRepositoryImpl _auth;

  /// Репозиторий планов, тем плана и занятий.
  final PlanRepositoryImpl _plans;

  /// Репозиторий своих тем и избранного.
  final TopicRepositoryImpl _topics;

  /// Репозиторий заметок.
  final NoteRepositoryImpl _notes;

  /// Репозиторий журнала Pomodoro.
  final PomodoroRepositoryImpl _pomodoros;

  /// Источник текущего времени.
  final DateTime Function() _clock;

  /// Криптостойкий генератор случайных чисел для токенов.
  final _random = Random.secure();

  /// Обработчик всех запросов. Pipeline — цепочка «прослоек» (middleware):
  /// сначала журнал, затем перехват ошибок, затем нужный маршрут.
  late final Handler handler = const Pipeline()
      .addMiddleware(_logRequests)
      .addMiddleware(_handleErrors)
      .addHandler(_buildRouter().call);

  /// Таблица маршрутов: метод HTTP + адрес → функция-обработчик.
  /// `<id|[0-9]+>` — часть адреса, которая передаётся в обработчик (только
  /// цифры).
  Router _buildRouter() {
    final r = Router(notFoundHandler: (_) => _error(404, 'Адрес не найден'));

    // Служебные адреса: страница сервера, проверка связи, каталог.
    r.get('/', _home);
    r.get('/api/health', _health);
    r.get('/api/directions', (Request _) => _json(catalog));

    // Регистрация, вход, выход и профиль.
    r.post('/api/auth/register', _register);
    r.post('/api/auth/login', _login);
    r.post('/api/auth/logout', _logout);
    r.get('/api/me', _me);
    r.put('/api/me', _updateProfile);
    r.delete('/api/me', _deleteAccount);
    r.put('/api/me/password', _changePassword);
    r.put('/api/me/reminder', _updateReminder);

    // Планы обучения.
    r.get('/api/plans', _listPlans);
    r.post('/api/plans', _createPlan);
    r.get('/api/plans/active', _activePlan);
    r.get('/api/plans/<id|[0-9]+>', _getPlan);
    r.patch('/api/plans/<id|[0-9]+>', _renamePlan);
    r.delete('/api/plans/<id|[0-9]+>', _deletePlan);
    r.post('/api/plans/<id|[0-9]+>/activate', _activatePlan);
    r.put('/api/plans/<id|[0-9]+>/settings', _updateSettings);
    r.get('/api/plans/<id|[0-9]+>/topics', _planTopics);
    r.put('/api/plans/<id|[0-9]+>/topics', _replacePlanTopics);
    r.get('/api/plans/<id|[0-9]+>/sessions', _planSessions);
    r.put('/api/plans/<id|[0-9]+>/sessions/open', _replaceOpenSessions);

    // Занятия.
    r.get('/api/sessions/completed', _completedSessions);
    r.get('/api/sessions/<id|[0-9]+>', _getSession);
    r.put('/api/sessions/<id|[0-9]+>/done', _setSessionDone);

    // Свои темы и избранное.
    r.get('/api/custom-topics', _listCustomTopics);
    r.post('/api/custom-topics', _createCustomTopic);
    r.get('/api/custom-topics/<id>', _getCustomTopic);
    r.put('/api/custom-topics/<id>', _updateCustomTopic);
    r.delete('/api/custom-topics/<id>', _deleteCustomTopic);
    r.get('/api/favorites', _favorites);
    r.post('/api/favorites/<topicId>/toggle', _toggleFavorite);

    // Заметки.
    r.get('/api/notes', _listNotes);
    r.post('/api/notes', _createNote);
    r.get('/api/notes/<id|[0-9]+>', _getNote);
    r.put('/api/notes/<id|[0-9]+>', _updateNote);
    r.delete('/api/notes/<id|[0-9]+>', _deleteNote);

    // Журнал Pomodoro.
    r.get('/api/pomodoros', _listPomodoros);
    r.post('/api/pomodoros', _logPomodoro);
    return r;
  }

  // ---------------------------------------------------------------------
  // Прослойки (middleware)
  // ---------------------------------------------------------------------

  /// Пишет в журнал строку о каждом запросе: время, метод, адрес, код
  /// ответа и сколько миллисекунд занял ответ.
  Handler _logRequests(Handler inner) => (request) async {
    // Засекаем время обработки.
    final watch = Stopwatch()..start();
    final response = await inner(request);
    // Время в виде ЧЧ:ММ:СС.
    final now = _clock().toIso8601String().substring(11, 19);
    final query = request.url.hasQuery ? '?${request.url.query}' : '';
    log?.call(
      '$now  ${request.method.padRight(6)} /${request.url.path}$query'
      '  →  ${response.statusCode}  (${watch.elapsedMilliseconds} мс)',
    );
    return response;
  };

  /// Перехватывает ошибки обработчиков и превращает их в ответ JSON с
  /// нужным кодом: так приложение всегда получает понятный текст ошибки.
  Handler _handleErrors(Handler inner) => (request) async {
    try {
      return await inner(request);
    } on HttpError catch (e) {
      // Ошибка, которую обработчик выбросил сам (401, 404 …).
      return _error(e.statusCode, e.message);
    } on AppException catch (e) {
      // Ошибка правил приложения: «email уже занят», «неверный пароль» …
      return _error(400, e.message);
    } on FormatException {
      // Неверный формат данных (например, дата не в формате ISO 8601).
      return _error(400, 'Некорректные данные в запросе');
    } on TypeError {
      // В JSON поле другого типа, чем ожидалось (строка вместо числа …).
      return _error(400, 'Некорректные данные в запросе');
    } on Object catch (e, stack) {
      // Непредвиденная ошибка: подробности — только в журнал сервера.
      log?.call('Ошибка сервера: $e\n$stack');
      return _error(500, 'Внутренняя ошибка сервера');
    }
  };

  // ---------------------------------------------------------------------
  // Вспомогательные функции
  // ---------------------------------------------------------------------

  /// Ответ с телом JSON. [status] — код ответа (по умолчанию 200 «OK»).
  Response _json(Object? body, {int status = 200}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Ответ 201 «Создано» с идентификатором новой записи.
  Response _created(Object id) => _json({'id': id}, status: 201);

  /// Ответ 204 «Нет содержимого»: действие выполнено, данных в ответе нет.
  Response _noContent() => Response(204);

  /// Ответ с ошибкой: код [status] и JSON `{"error": message}`.
  Response _error(int status, String message) =>
      _json({'error': message}, status: status);

  /// Читает тело запроса как JSON-объект.
  Future<Json> _body(Request request) async {
    final text = await request.readAsString();
    try {
      final data = jsonDecode(text);
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // Ниже ответим той же ошибкой, что и для не-объекта.
    }
    throw const HttpError(400, 'Тело запроса должно быть объектом JSON');
  }

  /// Достаёт из JSON обязательное поле типа [T] или отвечает ошибкой 400.
  T _field<T>(Json body, String name) {
    final value = body[name];
    if (value is T) return value;
    throw HttpError(400, 'Поле «$name» не заполнено или имеет неверный тип');
  }

  /// Необязательное поле типа [T]: `null`, если его нет.
  T? _optional<T>(Json body, String name) {
    final value = body[name];
    if (value == null || value is T) return value as T?;
    throw HttpError(400, 'Поле «$name» имеет неверный тип');
  }

  /// Список JSON-объектов из поля [name].
  List<Json> _objects(Json body, String name) =>
      _field<List<dynamic>>(body, name).cast<Json>();

  /// Повторная проверка данных на сервере теми же правилами, что и в
  /// формах приложения: первая найденная ошибка уходит ответом 400.
  void _validate(List<String?> errors) {
    for (final error in errors) {
      if (error != null) throw HttpError(400, error);
    }
  }

  /// Хэш токена SHA-256: в базе хранится он, а не сам токен.
  static String _hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  /// Выдаёт новый токен входа пользователю [userId] и возвращает его.
  /// Токен — 32 случайных байта в виде строки base64url.
  Future<String> issueToken(int userId) async {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final token = base64Url.encode(bytes).replaceAll('=', '');
    await db
        .into(db.apiTokens)
        .insert(
          ApiTokensCompanion.insert(
            tokenHash: _hashToken(token),
            userId: userId,
            createdAt: _clock(),
          ),
        );
    return token;
  }

  /// Токен из заголовка `Authorization: Bearer <токен>` или `null`.
  String? _tokenOf(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length).trim();
  }

  /// Определяет по токену, какой пользователь отправил запрос.
  /// Без токена или с устаревшим токеном — ошибка 401.
  Future<int> _userId(Request request) async {
    final token = _tokenOf(request);
    if (token == null) throw const HttpError(401, 'Требуется вход в аккаунт');
    // Ищем в базе запись с хэшем этого токена.
    final row = await (db.select(
      db.apiTokens,
    )..where((t) => t.tokenHash.equals(_hashToken(token)))).getSingleOrNull();
    // Токена нет или он старше срока действия.
    if (row == null || _clock().difference(row.createdAt) > tokenLifetime) {
      throw const HttpError(401, 'Сессия истекла, войдите снова');
    }
    return row.userId;
  }

  /// Проверяет, что план [planId] принадлежит пользователю [userId].
  Future<void> _ownPlan(int userId, int planId) async {
    final plan = await _plans.planById(planId);
    if (plan == null || plan.userId != userId) {
      throw const HttpError(404, 'План не найден');
    }
  }

  /// Возвращает занятие [sessionId], если оно из плана пользователя.
  Future<StudySession> _ownSession(int userId, int sessionId) async {
    final session = await _plans.sessionById(sessionId);
    final plan = session == null ? null : await _plans.planById(session.planId);
    if (session == null || plan == null || plan.userId != userId) {
      throw const HttpError(404, 'Занятие не найдено');
    }
    return session;
  }

  /// Возвращает строку своей темы [topicId], если тема принадлежит
  /// пользователю [userId]. id своей темы выглядит как `custom_12`.
  Future<CustomTopicRow> _ownCustomTopic(int userId, String topicId) async {
    final id = TopicRepositoryImpl.isCustomId(topicId)
        ? int.tryParse(
            topicId.substring(TopicRepositoryImpl.customPrefix.length),
          )
        : null;
    final row = id == null
        ? null
        : await (db.select(db.customTopics)
                ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
              .getSingleOrNull();
    if (row == null) throw const HttpError(404, 'Тема не найдена');
    return row;
  }

  /// Проверяет, что заметка [noteId] принадлежит пользователю [userId].
  Future<void> _ownNote(int userId, int noteId) async {
    final note = await _notes.noteById(noteId);
    if (note == null || note.userId != userId) {
      throw const HttpError(404, 'Заметка не найдена');
    }
  }

  // … обработчики запросов …
}
```

# ПРИЛОЖЕНИЕ Л. КЛИЕНТ API В ПРИЛОЖЕНИИ

Файл `lib/data/api/api_client.dart`.

```dart
/// Ошибка, которую вернул сервер (код ответа 4xx или 5xx).
class ApiException extends AppException {
  /// [statusCode] — код ответа HTTP, [message] — текст для пользователя.
  const ApiException(this.statusCode, super.message);

  /// Код ответа HTTP, например 400, 401, 404 или 500.
  final int statusCode;
}

/// Клиент API: отправляет запросы и разбирает ответы сервера.
class ApiClient {
  /// [baseUrl] — адрес сервера, например `http://192.168.1.5:8080`;
  /// [token] — токен входа, если пользователь уже вошёл;
  /// [httpClient] можно подменить в тестах;
  /// [timeout] — сколько ждать ответа сервера.
  ApiClient({
    required String baseUrl,
    this.token,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _baseUrl = normalizeUrl(baseUrl),
       _ownsHttp = httpClient == null,
       _http = httpClient ?? http.Client();

  /// Объект пакета http, который физически отправляет запросы.
  final http.Client _http;

  /// true, если объект http создан этим клиентом (тогда его закрывает
  /// [close]); переданный снаружи объект закрывает его владелец.
  final bool _ownsHttp;

  /// Предельное время ожидания ответа.
  final Duration timeout;

  /// Адрес сервера без косой черты в конце.
  String _baseUrl;

  /// Токен входа: отправляется в заголовке `Authorization`.
  String? token;

  /// Вызывается, когда сервер ответил 401 («нужно войти»): так приложение
  /// узнаёт, что токен устарел, и возвращает пользователя на экран входа.
  void Function()? onUnauthorized;

  /// Сигнал «данные на сервере изменились»: после каждого успешного запроса
  /// на изменение (POST, PUT, PATCH, DELETE) сюда приходит событие, и
  /// открытые экраны заново загружают свои данные.
  final _changes = StreamController<void>.broadcast();

  /// Поток событий об изменении данных.
  Stream<void> get changes => _changes.stream;

  /// Текущий адрес сервера.
  String get baseUrl => _baseUrl;

  /// Меняет адрес сервера (например, после правки в настройках входа).
  set baseUrl(String value) => _baseUrl = normalizeUrl(value);

  /// Приводит адрес к виду `http://хост:порт`: убирает пробелы и косую
  /// черту в конце, а если схема не указана — добавляет `http://`.
  static String normalizeUrl(String url) {
    // Убираем пробелы по краям и косые черты в конце адреса.
    var result = url.trim().replaceAll(RegExp(r'/+$'), '');
    // Пользователь мог ввести просто «192.168.1.5:8080».
    if (result.isNotEmpty && !result.contains('://')) {
      result = 'http://$result';
    }
    return result;
  }

  /// GET-запрос: получение данных.
  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  /// POST-запрос: создание записи или действие.
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  /// PUT-запрос: изменение записи целиком.
  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  /// PATCH-запрос: изменение части записи.
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  /// DELETE-запрос: удаление записи.
  Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body: body);

  /// Отправляет запрос и возвращает разобранный JSON ответа
  /// (`null`, если у ответа нет тела, например код 204).
  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    // Собираем полный адрес: сервер + путь + параметры запроса.
    final Uri uri;
    try {
      uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    } on FormatException {
      throw ConnectionException('Неверный адрес сервера: $_baseUrl');
    }
    // Адрес без хоста (например, пустой) отправить нельзя.
    if (!uri.hasAuthority || !uri.scheme.startsWith('http')) {
      throw ConnectionException(
        'Неверный адрес сервера: «$_baseUrl». Пример: http://192.168.1.5:8080',
      );
    }
    // Готовим запрос: метод, адрес, заголовки и тело в JSON.
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    // Токен входа передаётся в стандартном заголовке Authorization.
    final currentToken = token;
    if (currentToken != null) {
      request.headers['Authorization'] = 'Bearer $currentToken';
    }
    // Тело есть только у запросов с данными.
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      // Отправляем запрос и ждём ответ не дольше timeout.
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw ConnectionException(
        'Сервер $_baseUrl не отвечает. Проверьте, что сервер запущен.',
      );
    } on http.ClientException {
      // Нет сети, сервер выключен или адрес неверный.
      throw ConnectionException(
        'Нет связи с сервером $_baseUrl. Проверьте, что сервер запущен и '
        'телефон в той же сети Wi-Fi.',
      );
    }

    // Разбираем тело ответа (оно в UTF-8, чтобы не испортить кириллицу).
    final text = utf8.decode(response.bodyBytes);
    final Object? data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      throw ApiException(
        response.statusCode,
        'Сервер вернул ответ не в формате JSON (код ${response.statusCode})',
      );
    }

    // Успешный ответ (коды 200–299).
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Запрос на изменение прошёл — сообщаем экранам, что данные другие.
      if (method != 'GET') _changes.add(null);
      return data;
    }
    // Текст ошибки сервер присылает в поле error.
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Ошибка сервера (код ${response.statusCode})';
    // 401 — токен недействителен: просим войти заново.
    if (response.statusCode == 401) onUnauthorized?.call();
    throw ApiException(response.statusCode, message);
  }

  /// GET /api/health — проверяет, что по адресу [baseUrl] отвечает именно
  /// сервер «Маршрута». При ошибке выбрасывает [AppException] с причиной.
  Future<void> checkHealth() async {
    final data = await get('/api/health');
    if (data is! Map || data['service'] != 'Маршрут') {
      throw const ConnectionException(
        'По этому адресу отвечает не сервер «Маршрута»',
      );
    }
  }

  /// Поток данных, который обновляется сам: сразу загружает значение через
  /// [load], а потом загружает заново после каждого изменения данных
  /// (событие из [changes]). Если загрузка не удалась, поток передаёт
  /// ошибку экрану и через [retryDelay] пробует ещё раз.
  Stream<T> watch<T>(
    Future<T> Function() load, {
    Duration retryDelay = const Duration(seconds: 5),
  }) {
    // Поток, который получит экран.
    late final StreamController<T> controller;
    // Подписка на события об изменении данных.
    StreamSubscription<void>? subscription;
    // Таймер повторной попытки после ошибки.
    Timer? retry;
    // Номер последнего запроса: ответ на устаревший запрос отбрасывается.
    var generation = 0;
    // true, когда экран закрыт и данные больше не нужны.
    var cancelled = false;

    // Загружает данные и передаёт их в поток.
    Future<void> refresh() async {
      retry?.cancel();
      final current = ++generation;
      try {
        final value = await load();
        // Пока ждали ответ, мог уйти более новый запрос или экран закрылся.
        if (current == generation && !cancelled) controller.add(value);
      } on Object catch (error, stack) {
        if (current != generation || cancelled) return;
        // Показываем ошибку и через несколько секунд пробуем снова.
        controller.addError(error, stack);
        retry = Timer(retryDelay, refresh);
      }
    }

    controller = StreamController<T>(
      // Экран подписался: следим за изменениями и загружаем данные.
      onListen: () {
        subscription = changes.listen((_) => refresh());
        refresh();
      },
      // Экран закрыт: отписываемся и отменяем повтор.
      onCancel: () async {
        cancelled = true;
        retry?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Закрывает соединения (при завершении работы).
  void close() {
    if (_ownsHttp) _http.close();
    _changes.close();
  }
}
```
