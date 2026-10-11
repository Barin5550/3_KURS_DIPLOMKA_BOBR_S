import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/utils/password_hasher.dart';

void main() {
  final hasher = PasswordHasher();

  test('хэш детерминирован для одинаковых соли и пароля', () {
    expect(hasher.hash('qwerty123', 'salt'), hasher.hash('qwerty123', 'salt'));
  });

  test('хэш — 64 шестнадцатеричных символа SHA-256', () {
    expect(hasher.hash('qwerty123', 'salt'), matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('известное значение SHA-256 («abc»)', () {
    expect(
      hasher.hash('abc', ''),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
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
}
