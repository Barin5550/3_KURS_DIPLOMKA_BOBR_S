import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/utils/password_hasher.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // Мало итераций, чтобы тесты шли быстро; алгоритм от этого не меняется.
  final hasher = PasswordHasher(iterations: 1000);

  group('PBKDF2-HMAC-SHA256', () {
    // Эталонные значения посчитаны независимо: Python hashlib.pbkdf2_hmac.
    test('тестовый вектор: passwd / salt / 1 итерация', () {
      expect(
        hex(
          PasswordHasher.pbkdf2(utf8.encode('passwd'), utf8.encode('salt'), 1),
        ),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('тестовый вектор: password / salt / 4096 итераций', () {
      expect(
        hex(
          PasswordHasher.pbkdf2(
            utf8.encode('password'),
            utf8.encode('salt'),
            4096,
          ),
        ),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('кириллический пароль', () {
      expect(
        hasher.hash('пароль2026', 'c2FsdA=='),
        'pbkdf2_sha256\$1000\$'
        '90886b387fd2875d51d3ef521c392f76e060e2d05a585924c368b501da8b9462',
      );
    });
  });

  test('хэш хранит схему и число итераций', () {
    expect(
      hasher.hash('qwerty123', 'salt'),
      matches(RegExp(r'^pbkdf2_sha256\$1000\$[0-9a-f]{64}$')),
    );
  });

  test('разная соль даёт разные хэши для одного пароля', () {
    final s1 = hasher.generateSalt();
    final s2 = hasher.generateSalt();
    expect(s1, isNot(s2));
    expect(hasher.hash('qwerty123', s1), isNot(hasher.hash('qwerty123', s2)));
  });

  test('verify принимает верный пароль и отклоняет неверный', () {
    final salt = hasher.generateSalt();
    final hash = hasher.hash('flutter2026', salt);
    expect(hasher.verify('flutter2026', salt, hash), isTrue);
    expect(hasher.verify('flutter2025', salt, hash), isFalse);
  });

  test('хэш с другим числом итераций проверяется по своему числу', () {
    final salt = hasher.generateSalt();
    final old = PasswordHasher(iterations: 10).hash('flutter2026', salt);
    expect(hasher.verify('flutter2026', salt, old), isTrue);
    expect(hasher.needsRehash(old), isTrue);
    expect(hasher.needsRehash(hasher.hash('flutter2026', salt)), isFalse);
  });

  test('hashAsync и verifyAsync в изоляте дают тот же результат', () async {
    // От 10 000 итераций расчёт выносится в отдельный изолят.
    final slow = PasswordHasher(iterations: 20000);
    final salt = slow.generateSalt();
    final hash = await slow.hashAsync('flutter2026', salt);
    expect(hash, slow.hash('flutter2026', salt));
    expect(await slow.verifyAsync('flutter2026', salt, hash), isTrue);
    expect(await slow.verifyAsync('flutter2025', salt, hash), isFalse);
  });

  group('совместимость с версией 1 семестра (SHA-256)', () {
    test('известное значение SHA-256 («abc»)', () {
      expect(
        PasswordHasher.legacyHash('abc', ''),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('старый хэш проверяется и помечается для пересчёта', () {
      final legacy = PasswordHasher.legacyHash('flutter2026', 'salt');
      expect(hasher.verify('flutter2026', 'salt', legacy), isTrue);
      expect(hasher.verify('wrong', 'salt', legacy), isFalse);
      expect(hasher.needsRehash(legacy), isTrue);
    });

    test('повреждённая запись не проходит проверку', () {
      expect(hasher.verify('x', 'salt', r'pbkdf2_sha256$abc$00'), isFalse);
      expect(hasher.verify('x', 'salt', ''), isFalse);
    });
  });
}
