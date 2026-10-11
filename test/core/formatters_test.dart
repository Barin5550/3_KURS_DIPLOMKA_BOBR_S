import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/core/utils/formatters.dart';

void main() {
  test('plural склоняет существительное после целого числа', () {
    String lessons(int n) => Fmt.plural(n, 'занятие', 'занятия', 'занятий');
    expect(lessons(1), 'занятие');
    expect(lessons(21), 'занятие');
    expect(lessons(2), 'занятия');
    expect(lessons(32), 'занятия');
    expect(lessons(5), 'занятий');
    expect(lessons(11), 'занятий');
    expect(lessons(12), 'занятий');
    expect(lessons(111), 'занятий');
  });

  test('hoursWord: после дробного числа «часа»', () {
    expect(Fmt.hoursWord(1), 'час');
    expect(Fmt.hoursWord(3), 'часа');
    expect(Fmt.hoursWord(5), 'часов');
    expect(Fmt.hoursWord(23.8), 'часа');
    expect(Fmt.hoursWord(0.5), 'часа');
    // 4,96 округляется до 5 — согласуется с округлённым значением.
    expect(Fmt.hoursWord(4.96), 'часов');
  });

  test('hours и minutes', () {
    expect(Fmt.hours(23.84), '23,8');
    expect(Fmt.hours(8.0), '8');
    expect(Fmt.minutes(45), '45 мин');
    expect(Fmt.minutes(120), '2 ч');
    expect(Fmt.minutes(250), '4 ч 10 мин');
  });
}
