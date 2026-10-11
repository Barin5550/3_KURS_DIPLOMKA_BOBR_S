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
