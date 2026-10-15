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
