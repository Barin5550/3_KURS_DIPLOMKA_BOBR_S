// Файл user.dart — сущность «пользователь» (AppUser).
// Слой: domain (бизнес-модели, не зависят от Flutter и базы данных).
// Объект создаёт AuthRepositoryImpl (data) из строки таблицы пользователей,
// а читают AuthController и экраны профиля (presentation).
/// Пользователь приложения.
///
/// Неизменяемый объект: все поля `final`, конструктор `const`.
class AppUser {
  /// Создаёт пользователя. Напоминание по умолчанию выключено,
  /// время по умолчанию — 19:00.
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarColor,
    required this.createdAt,
    this.reminderEnabled = false,
    this.reminderHour = 19,
    this.reminderMinute = 0,
  });

  /// Номер пользователя в базе данных.
  final int id;

  /// Имя, которое пользователь указал при регистрации.
  final String name;

  /// Email — логин для входа.
  final String email;

  /// Цвет аватара в формате 0xAARRGGBB.
  final int avatarColor;

  /// Дата и время регистрации.
  final DateTime createdAt;

  /// Ежедневное напоминание о занятиях.
  final bool reminderEnabled;

  /// Час напоминания (0–23).
  final int reminderHour;

  /// Минуты напоминания (0–59).
  final int reminderMinute;

  /// Инициалы для круглого аватара: «Иван Петров» → «ИП», «Иван» → «И».
  String get initials {
    // Делим имя на слова по любым пробелам.
    final parts = name.trim().split(RegExp(r'\s+'));
    // Имя пустое — показываем знак вопроса.
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    // Одно слово — одна заглавная буква.
    if (parts.length == 1) return parts.first[0].toUpperCase();
    // Два и больше слов — первые буквы первых двух слов.
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
