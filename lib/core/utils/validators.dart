/// Валидаторы полей форм. Возвращают текст ошибки или `null`, если всё верно.
///
/// Сигнатура `String? Function(String?)` совпадает с параметром
/// `validator` у `TextFormField`.
abstract final class Validators {
  static final _emailRegExp = RegExp(
    r'^[\w.+-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$',
  );
  static final _nameRegExp = RegExp(r"^[a-zA-Zа-яА-ЯёЁ\s'-]+$");

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите имя';
    if (v.length < 2) return 'Имя должно содержать не менее 2 символов';
    if (v.length > 40) return 'Имя должно содержать не более 40 символов';
    if (!_nameRegExp.hasMatch(v)) {
      return 'Имя может содержать только буквы, пробел и дефис';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите email';
    if (!_emailRegExp.hasMatch(v)) {
      return 'Введите корректный email, например name@mail.ru';
    }
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < 8) return 'Пароль должен содержать не менее 8 символов';
    if (!RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(v) ||
        !RegExp(r'\d').hasMatch(v)) {
      return 'Пароль должен содержать буквы и цифры';
    }
    return null;
  }

  /// Для входа достаточно непустого пароля: правила сложности проверяются
  /// при регистрации.
  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Введите пароль' : null;

  static String? Function(String?) confirmPassword(String Function() original) =>
      (value) {
        if (value == null || value.isEmpty) return 'Повторите пароль';
        if (value != original()) return 'Пароли не совпадают';
        return null;
      };

  static String? requiredText(String? value, {String field = 'поле'}) =>
      (value == null || value.trim().isEmpty) ? 'Заполните $field' : null;

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите название';
    if (v.length > 80) return 'Название должно быть не длиннее 80 символов';
    return null;
  }

  /// Длительность темы в часах: число от 0,5 до 100 (допускается запятая).
  static String? hours(String? value) {
    final v = value?.trim().replaceAll(',', '.') ?? '';
    if (v.isEmpty) return 'Укажите количество часов';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Введите число, например 2 или 1,5';
    if (parsed < 0.5 || parsed > 100) return 'От 0,5 до 100 часов';
    return null;
  }

  static double parseHours(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));
}
