import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Хэширование паролей: SHA-256 от строки «соль + пароль».
///
/// Соль — 16 случайных байт из криптостойкого генератора [Random.secure].
/// Благодаря соли одинаковые пароли разных пользователей дают разные хэши,
/// а готовые таблицы хэшей («радужные таблицы») бесполезны.
class PasswordHasher {
  PasswordHasher({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String generateSalt([int length = 16]) {
    final bytes = List<int>.generate(length, (_) => _random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  bool verify(String password, String salt, String expectedHash) {
    final actual = hash(password, salt);
    // Сравнение без раннего выхода, чтобы время не зависело от совпадения.
    if (actual.length != expectedHash.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
    }
    return diff == 0;
  }
}
