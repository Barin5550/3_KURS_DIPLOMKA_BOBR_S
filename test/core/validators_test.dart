import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('пустое значение', () {
      expect(Validators.email(''), 'Введите email');
      expect(Validators.email(null), 'Введите email');
    });
    test('некорректные адреса', () {
      for (final bad in ['abc', 'a@b', 'a@b.', '@mail.ru', 'a b@mail.ru']) {
        expect(Validators.email(bad), isNotNull, reason: bad);
      }
    });
    test('корректные адреса', () {
      for (final good in [
        'name@mail.ru',
        'a.b+c@gmail.com',
        'x@sub.domain.kz',
      ]) {
        expect(Validators.email(good), isNull, reason: good);
      }
    });
  });

  group('Validators.password', () {
    test('короткий пароль', () {
      expect(Validators.password('abc123'), contains('не менее 8'));
    });
    test('без цифр или без букв', () {
      expect(Validators.password('abcdefgh'), contains('буквы и цифры'));
      expect(Validators.password('12345678'), contains('буквы и цифры'));
    });
    test('надёжный пароль', () {
      expect(Validators.password('flutter2026'), isNull);
      expect(Validators.password('пароль2026'), isNull);
    });
  });

  group('Validators.name', () {
    test('проверяет длину и символы', () {
      expect(Validators.name(''), 'Введите имя');
      expect(Validators.name('А'), contains('не менее 2'));
      expect(Validators.name('R2D2'), contains('только буквы'));
      expect(Validators.name('Анна-Мария'), isNull);
      expect(Validators.name('Alex Smith'), isNull);
    });
  });

  test('confirmPassword сравнивает с исходным паролем', () {
    var original = 'secret123';
    final validator = Validators.confirmPassword(() => original);
    expect(validator(''), 'Повторите пароль');
    expect(validator('secret124'), 'Пароли не совпадают');
    expect(validator('secret123'), isNull);
    original = 'changed1';
    expect(validator('secret123'), 'Пароли не совпадают');
  });

  test('hours принимает запятую и проверяет диапазон', () {
    expect(Validators.hours('1,5'), isNull);
    expect(Validators.hours('2'), isNull);
    expect(Validators.hours('0.2'), isNotNull);
    expect(Validators.hours('abc'), isNotNull);
    expect(Validators.parseHours('1,5'), 1.5);
  });
}
